import SwiftUI

struct ResultTable: View {
    let records: [RepairRecord]
    @Binding var selectedIDs: Set<UUID>
    @Binding var sortOrder: [KeyPathComparator<RepairRecord>]
    var showSelection: Bool // 控制是否顯示勾選欄
    var onCopy: (String) -> Void
    
    // 1. 在這裡應用 sortOrder 進行實際排序
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
            // 2. 傳入 sortedRecords 確保畫面顯示的是排序後的結果
            Table(sortedRecords, sortOrder: $sortOrder) {
                
                // 3. 使用 if 條件式完全移除選取欄位
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
                
                // 其他欄位 (保持 value 參數以支援排序)
                TableColumn("GSX 單號", value: \.gsxID) { r in cellGSX(r) }
                    .width(min: 120)
                
                TableColumn("RMA 單號", value: \.rmaID) { r in cellRMA(r) }
                    .width(min: 120)
                
                TableColumn("SA 狀態", value: \.saStatus) { r in cellSAStatus(r) }
                    .width(min: 100)
                
                TableColumn("GSX 狀態", value: \.gsxStatus) { r in cellGSXStatus(r) }
                    .width(min: 150)
                
                // 修正：移除 value: \.isAnomaly，因為 Bool 不能直接排序
                TableColumn("異常") { r in cellAnomaly(r) }
                    .width(50)
            }
            .onChange(of: sortOrder) { _, _ in
                // 因為使用了 computed property (sortedRecords)，畫面會自動更新
            }
            .scrollContentBackground(.hidden)
        }
    }
    
    // MARK: - 提取 Cell 視圖
    
    @ViewBuilder
    private func cellGSX(_ r: RepairRecord) -> some View {
        Text(r.gsxID)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { onCopy(r.gsxID) }
            .contextMenu { Button("複製單號") { onCopy(r.gsxID) } }
            .help("雙擊複製 GSX 單號")
    }
    
    @ViewBuilder
    private func cellRMA(_ r: RepairRecord) -> some View {
        Text(r.rmaID)
            .foregroundStyle(.white.opacity(0.8))
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { onCopy(r.rmaID) }
            .contextMenu { Button("複製 RMA") { onCopy(r.rmaID) } }
            .help("雙擊複製 RMA 單號")
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
