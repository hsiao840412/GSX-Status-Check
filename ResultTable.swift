import SwiftUI

struct ResultTable: View {
    let records: [RepairRecord]
    @Binding var selectedIDs: Set<UUID>
    @Binding var sortOrder: [KeyPathComparator<RepairRecord>]
    var showSelection: Bool // 控制是否顯示勾選欄
    var onCopy: (String) -> Void
    
    // 排序邏輯
    var sortedRecords: [RepairRecord] {
        records.sorted(using: sortOrder)
    }
    
    var body: some View {
        if records.isEmpty {
            VStack(spacing: 15) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundStyle(.white.opacity(0.1))
                Text("無資料( ´•̥̥̥ω•̥̥̥` )")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.3))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Table(sortedRecords, sortOrder: $sortOrder) {
                
                // 選取欄位
                if showSelection {
                    TableColumn("選取") { r in
                        Toggle("", isOn: Binding(
                            get: { selectedIDs.contains(r.id) },
                            set: { isSelected in
                                if isSelected { selectedIDs.insert(r.id) }
                                else { selectedIDs.remove(r.id) }
                            }
                        ))
                        .labelsHidden()
                    }
                    .width(40)
                }
                
                // === GSX 單號 (白底藍色 Safari) ===
                TableColumn("GSX 單號", value: \.gsxID) { r in cellGSX(r) }
                    .width(min: 150)
                
                // === RMA 單號 (白底藍色 Safari) ===
                TableColumn("RMA 單號", value: \.rmaID) { r in cellRMA(r) }
                    .width(min: 150)
                
                TableColumn("SA 狀態", value: \.saStatus) { r in cellSAStatus(r) }
                    .width(min: 100)
                
                TableColumn("GSX 狀態", value: \.gsxStatus) { r in cellGSXStatus(r) }
                    .width(min: 150)
                
                TableColumn("異常") { r in cellAnomaly(r) }
                    .width(50)
            }
            .onChange(of: sortOrder) { _, _ in }
            .scrollContentBackground(.hidden)
        }
    }
    
    // MARK: - 輔助功能：開啟網頁
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Cell 視圖
    
    @ViewBuilder
    private func cellGSX(_ r: RepairRecord) -> some View {
        HStack {
            // 單號文字
            Text(r.gsxID)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.white)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { onCopy(r.gsxID) }
            
            Spacer() // 將按鈕推到右邊
            
            // GSX 按鈕 (白底藍色 Safari)
            if r.gsxID != "-" && !r.gsxID.isEmpty {
                Button(action: {
                    openURL("https://gsx2.apple.com/repairs/\(r.gsxID)")
                }) {
                    Image(systemName: "safari.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.blue) // 藍色圖示
                        .padding(6)
                        .background(Circle().fill(Color.white)) // 白色背景
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                .help("在瀏覽器開啟 GSX")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contextMenu {
            Button("複製單號") { onCopy(r.gsxID) }
            Button("開啟 GSX 網頁") {
                openURL("https://gsx2.apple.com/repairs/\(r.gsxID)")
            }
        }
    }
    
    @ViewBuilder
    private func cellRMA(_ r: RepairRecord) -> some View {
        HStack {
            // 單號文字
            Text(r.rmaID)
                .foregroundStyle(.white.opacity(0.8))
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { onCopy(r.rmaID) }
            
            Spacer() // 將按鈕推到右邊
            
            // RMA 按鈕 (白底藍色 Safari，樣式統一)
            if r.rmaID != "-" && !r.rmaID.isEmpty {
                Button(action: {
                    openURL("https://rma0.studioarma.com/rma/?m=ticket-common&op=view&id=\(r.rmaID)")
                }) {
                    Image(systemName: "safari.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.blue) // 藍色圖示
                        .padding(6)
                        .background(Circle().fill(Color.white)) // 白色背景
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                .help("開啟 RMA 系統")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contextMenu {
            Button("複製 RMA") { onCopy(r.rmaID) }
            Button("開啟 RMA 網頁") {
                openURL("https://rma0.studioarma.com/rma/?m=ticket-common&op=view&id=\(r.rmaID)")
            }
        }
    }
    
    @ViewBuilder
    private func cellSAStatus(_ r: RepairRecord) -> some View {
        Text(r.saStatus)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(r.isAnomaly ? Color.orange.opacity(0.2) : Color.clear)
            .foregroundStyle(r.isAnomaly ? .orange : .white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    @ViewBuilder
    private func cellGSXStatus(_ r: RepairRecord) -> some View {
        Text(r.gsxStatus)
            .foregroundStyle(.white.opacity(0.7))
    }
    
    @ViewBuilder
    private func cellAnomaly(_ r: RepairRecord) -> some View {
        if r.isAnomaly {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red.opacity(0.8))
        } else {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green.opacity(0.5))
        }
    }
}
