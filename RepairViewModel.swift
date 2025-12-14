import SwiftUI
import Combine
import AppKit
import UniformTypeIdentifiers

@MainActor
class RepairViewModel: ObservableObject {
    @Published var saPath: String = ""
    @Published var gsxPath: String = ""
    
    @Published var isAnalyzing: Bool = false
    @Published var unclosedRecords: [RepairRecord] = []
    @Published var notReadyRecords: [RepairRecord] = []
    @Published var allMatchedRecords: [RepairRecord] = []
    @Published var selectedIDs: Set<UUID> = []
    @Published var statusMessage: String = "等待中..."
    
    func toggleSelectAll(records: [RepairRecord]) {
        let currentIDs = Set(records.map { $0.id })
        if selectedIDs.isSuperset(of: currentIDs) {
            selectedIDs.subtract(currentIDs)
        } else {
            selectedIDs.formUnion(currentIDs)
        }
    }
    
    func analyze() {
        guard !saPath.isEmpty, !gsxPath.isEmpty else {
            statusMessage = "❌ 請先選擇兩個檔案"
            return
        }
        
        isAnalyzing = true
        statusMessage = "正在分析..."
        selectedIDs.removeAll()
        
        let currentSaPath = saPath
        let currentGsxPath = gsxPath
        
        Task.detached {
            guard let saURL = URL(string: currentSaPath),
                  let gsxURL = URL(string: currentGsxPath) else { return }
            
            guard let saRes = CSVParser.parse(url: saURL),
                  let gsxRes = CSVParser.parse(url: gsxURL) else {
                await MainActor.run { self.isAnalyzing = false; self.statusMessage = "❌ 檔案分析失敗" }
                return
            }
            
            let gsxData = gsxRes.rows
            let saData = saRes.rows
            
            let gsxHeaders = gsxRes.headers
            let poHeader = gsxHeaders.first { $0 == "採購訂單" }
                        ?? gsxHeaders.first { $0.contains("採購") || $0.contains("Purchase") || $0.contains("PO") }
            let idHeader = gsxHeaders.first { $0 == "維修" || $0 == "維修 ID" }
                        ?? gsxHeaders.first { $0.contains("Repair ID") }
            let gsxStatusHeader = gsxHeaders.first { $0 == "維修狀態" }
                               ?? gsxHeaders.first { $0.contains("Repair Status") || $0.contains("Status") }
            
            guard let validPO = poHeader else {
                await MainActor.run { self.isAnalyzing = false; self.statusMessage = "❌ 找不到 GSX '採購訂單' 欄位" }
                return
            }
            
            var gsxMap: [String: [String: String]] = [:]
            for row in gsxData {
                if let val = row[validPO] {
                    let raw = val.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "")
                    let baseKey = raw.components(separatedBy: "-").first ?? raw
                    if !baseKey.isEmpty { gsxMap[baseKey] = row }
                }
            }
            
            let saHeaders = saRes.headers
            let saRmaKey = saHeaders.first { $0 == "單號" || $0 == "Order No" }
                        ?? saHeaders.first { $0.contains("單號") || $0.contains("Order") }
                        ?? "單號"
            
            let saStatusKey = saHeaders.first { $0 == "狀態" || $0 == "Status" }
                           ?? saHeaders.first { $0.contains("狀態") && !$0.contains("保固") }
                           ?? saHeaders.first { $0.contains("Status") }
                           ?? "狀態"
            
            var localUnclosed: [RepairRecord] = []
            var localNotReady: [RepairRecord] = []
            var localAll: [RepairRecord] = []
            var matchCount = 0
            
            for saRow in saData {
                guard let rmaRaw = saRow[saRmaKey], let saStatusRaw = saRow[saStatusKey] else { continue }
                
                let saStatus = saStatusRaw.trimmingCharacters(in: .whitespacesAndNewlines)
                let rmaClean = rmaRaw.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "")
                let saBaseKey = rmaClean.components(separatedBy: "-").first ?? rmaClean
                
                let gsxRow = gsxMap[saBaseKey]
                
                if let row = gsxRow {
                    matchCount += 1
                    let gsxStatusRaw = (gsxStatusHeader != nil ? row[gsxStatusHeader!] : nil) ?? "N/A"
                    let gsxStatus = gsxStatusRaw.trimmingCharacters(in: .whitespacesAndNewlines)
                    let gsxID = (idHeader != nil ? row[idHeader!] : nil) ?? "-"
                    let date = row["建立日期"] ?? "-"
                    
                    var isAnomaly = false
                    var record = RepairRecord(gsxID: gsxID, rmaID: rmaRaw, saStatus: saStatus, gsxStatus: gsxStatus, date: date, isAnomaly: false)
                    
                    if saStatus.contains("顧客領回") && !gsxStatus.contains("已由系統關閉") && !gsxStatus.contains("Closed") {
                        isAnomaly = true
                        record = RepairRecord(id: record.id, gsxID: gsxID, rmaID: rmaRaw, saStatus: saStatus, gsxStatus: gsxStatus, date: date, isAnomaly: true)
                        localUnclosed.append(record)
                    }
                    
                    let targetStatuses = ["抵達門市", "工程師完成", "寄送到門市"]
                    let isTargetStatus = targetStatuses.contains { saStatus.contains($0) }
                    
                    if isTargetStatus && !gsxStatus.contains("待取件") && !gsxStatus.contains("Pickup") && !gsxStatus.contains("已由系統關閉") {
                        isAnomaly = true
                        record = RepairRecord(id: record.id, gsxID: gsxID, rmaID: rmaRaw, saStatus: saStatus, gsxStatus: gsxStatus, date: date, isAnomaly: true)
                        localNotReady.append(record)
                    }
                    
                    localAll.append(record)
                }
            }
            
            await MainActor.run {
                self.unclosedRecords = localUnclosed
                self.notReadyRecords = localNotReady
                self.allMatchedRecords = localAll
                self.isAnalyzing = false
                
                if matchCount == 0 {
                    self.statusMessage = "⚠️ 分析完成：未發現匹配資料"
                } else {
                    self.statusMessage = "✅ 分析完成：已處理 \(matchCount) 筆數據"
                    let unclosedIDs = localUnclosed.map { $0.id }
                    self.selectedIDs.formUnion(unclosedIDs)
                }
            }
        }
    }
    
    func exportCSV(records: [RepairRecord], filename: String) {
        let filteredRecords = records.filter { selectedIDs.contains($0.id) }
        
        if filteredRecords.isEmpty {
            statusMessage = "⚠️ 匯出取消：未選取任何項目"
            return
        }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = filename
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.title = "匯出 GSX 多裝置上傳報表"
        panel.message = "將匯出 \(filteredRecords.count) 筆數據"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let row1 = "Status,Repair ID,Repair Status,Technician ID,Part Details,Error Message"
                let row2 = ",repairId,repairStatus,technicianId,\"parts[number, kgbDeviceDetail.id]\","
                var csvString = "\u{FEFF}\(row1)\n\(row2)\n"
                
                for record in filteredRecords {
                    let rowString = ",\(record.gsxID),SPCM,,,"
                    csvString += "\(rowString)\n"
                }
                
                do {
                    try csvString.write(to: url, atomically: true, encoding: .utf8)
                    self.statusMessage = "✅ 匯出成功：\(filteredRecords.count) 筆"
                } catch {
                    self.statusMessage = "❌ 匯出失敗：\(error.localizedDescription)"
                }
            }
        }
    }
    
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        statusMessage = "📋 已複製：\(text)"
    }
}
