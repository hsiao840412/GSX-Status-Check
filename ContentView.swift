import SwiftUI
import UniformTypeIdentifiers
import AppKit

// ==========================================
// 4. View (主畫面)
// ==========================================
struct ContentView: View {
    @StateObject private var vm = RepairViewModel()
    @StateObject private var updater = UpdateManager()
    @State private var selectedTab = 0
    @State private var sortOrder = [KeyPathComparator(\RepairRecord.date)]
    @State private var isDraggingSA = false
    @State private var isDraggingGSX = false
    
    // Toast 狀態
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    
    var currentRecords: [RepairRecord] {
        switch selectedTab {
        case 0: return vm.unclosedRecords
        case 1: return vm.notReadyRecords
        default: return vm.allMatchedRecords
        }
    }
    
    var selectedCountInCurrentTab: Int {
        currentRecords.filter { vm.selectedIDs.contains($0.id) }.count
    }
    
    var body: some View {
        ZStack {
            // 背景層
            LinearGradient(
                colors: [Color(hex: "0F2027"), Color(hex: "203A43"), Color(hex: "2C5364")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 裝飾光暈
            Circle()
                .fill(Color.cyan.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: -200, y: -200)
            
            Circle()
                .fill(Color.purple.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: 200, y: 150)
            
            VStack(spacing: 20) {
                
                // === 頂部玻璃面板 ===
                VStack(alignment: .leading, spacing: 15) {
                    HStack(alignment: .center) {
                        Image(systemName: "bolt.horizontal.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .shadow(color: .cyan.opacity(0.5), radius: 10, x: 0, y: 0)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("GSX狀態檢查工具")
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                            
                            HStack(spacing: 6) {
                                Text("v4.4")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.white.opacity(0.1)))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                            }
                        }
                        Spacer()
                    }
                    
                    // 檔案選擇區
                    HStack(spacing: 15) {
                        GlassFilePicker(
                            title: "SA 報表 (Report...)",
                            icon: "doc.text.fill",
                            path: $vm.saPath,
                            isDragging: isDraggingSA
                        )
                        .onDrop(of: [.fileURL], isTargeted: $isDraggingSA) { providers in
                            loadPath(from: providers) { url in vm.saPath = url.absoluteString }
                            return true
                        }
                        
                        GlassFilePicker(
                            title: "GSX 報表 (repair_data...)",
                            icon: "server.rack",
                            path: $vm.gsxPath,
                            isDragging: isDraggingGSX
                        )
                        .onDrop(of: [.fileURL], isTargeted: $isDraggingGSX) { providers in
                            loadPath(from: providers) { url in vm.gsxPath = url.absoluteString }
                            return true
                        }
                    }
                    
                    // 分析按鈕與狀態
                    HStack(spacing: 15) {
                        Button(action: { vm.analyze() }) {
                            HStack {
                                if vm.isAnalyzing {
                                    ProgressView().controlSize(.small).tint(.black)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(vm.isAnalyzing ? "正在分析..." : "開始比對")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .cyan.opacity(0.4), radius: 8, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.isAnalyzing)
                        
                        // 狀態顯示
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.white.opacity(0.6))
                            Text(vm.statusMessage)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.9))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                        .background(Color.black.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 1))
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // === 內容區 ===
                VStack(spacing: 0) {
                    // 控制列 (Tabs & Actions)
                    HStack {
                        GlassTab(title: "未關單", count: vm.unclosedRecords.count, idx: 0, sel: $selectedTab, color: .orange)
                        GlassTab(title: "未改待取", count: vm.notReadyRecords.count, idx: 1, sel: $selectedTab, color: .purple)
                        GlassTab(title: "所有", count: vm.allMatchedRecords.count, idx: 2, sel: $selectedTab, color: .blue)
                        
                        Spacer()
                        
                        // 雙擊複製提示
                        if !currentRecords.isEmpty {
                            Text("💡 雙擊單號即可複製")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.trailing, 10)
                                .transition(.opacity)
                        }
                        
                        // 功能按鈕群
                        HStack(spacing: 8) {
                            // [修改] 只有在「未關單」(idx=0) 且有資料時，才顯示「全選」按鈕
                            if selectedTab == 0 && !currentRecords.isEmpty {
                                ActionButton(
                                    icon: selectedCountInCurrentTab == currentRecords.count ? "checkmark.circle.fill" : "circle",
                                    label: "全選",
                                    isActive: selectedCountInCurrentTab > 0
                                ) {
                                    vm.toggleSelectAll(records: currentRecords)
                                }
                            }
                            
                            // [修改] 匯出按鈕也只在 idx=0 顯示 (邏輯維持不變)
                            if selectedTab == 0 {
                                ActionButton(
                                    icon: "square.and.arrow.up.fill",
                                    label: "匯出 (\(selectedCountInCurrentTab))",
                                    isActive: selectedCountInCurrentTab > 0,
                                    isHighlight: true
                                ) {
                                    let filename = "GSX多裝置上傳清單_\(Date().formatted(.iso8601.year().month().day().dateSeparator(.dash))).csv"
                                    vm.exportCSV(records: currentRecords, filename: filename)
                                }
                                .disabled(selectedCountInCurrentTab == 0)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.black.opacity(0.2))
                    
                    // 表格區
                    ResultTable(
                        records: currentRecords,
                        selectedIDs: $vm.selectedIDs,
                        sortOrder: $sortOrder,
                        showSelection: selectedTab == 0 // [修改] 傳入參數：只有 Tab 0 才顯示勾選欄
                    ) { text in
                        vm.copyToClipboard(text)
                        triggerToast(msg: "已複製：\(text)")
                    }
                    .padding(.bottom, 10)
                }
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            
            // 浮動 Toast 通知
            if showToast {
                VStack {
                    Spacer()
                    GlassToast(message: toastMessage)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 50)
                }
                .zIndex(100)
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .task {
                    // App 啟動時自動檢查
                    updater.checkForUpdates()
                }
                .alert("發現新版本 \(updater.latestVersion)", isPresented: $updater.hasUpdate) {
                    Button("前往下載") {
                        if let url = updater.releaseURL {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    Button("稍後", role: .cancel) { }
                } message: {
                    // 這裡顯示你在 GitHub 寫的 Release Notes
                    Text(updater.releaseNotes)
                }
    }
    
    
    // Toast 觸發邏輯
    func triggerToast(msg: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            toastMessage = msg
            showToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.3)) {
                showToast = false
            }
        }
    }
    
    func loadPath(from providers: [NSItemProvider], completion: @escaping (URL) -> Void) {
        guard let provider = providers.first else { return }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
            if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                DispatchQueue.main.async { completion(url) }
            } else if let url = item as? URL {
                DispatchQueue.main.async { completion(url) }
            }
        }
    }
}

#Preview {
    ContentView()
}
