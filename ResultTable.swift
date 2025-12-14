import SwiftUI

struct ResultTable: View {
    let records: [RepairRecord]
    @Binding var selectedIDs: Set<UUID>
    @Binding var sortOrder: [KeyPathComparator<RepairRecord>]
    var showSelection: Bool // <--- 新增這個變數：控制是否顯示勾選欄
    var onCopy: (String) -> Void
    
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
            Table(records, sortOrder: $sortOrder) {
                // 只有當 showSelection 為真時，才建立這個欄位
                TableColumn("選取") { r in
                    if showSelection {
                        Toggle("", isOn: Binding(
                            get: { selectedIDs.contains(r.id) },
                            set: { isSelected in
                                if isSelected { selectedIDs.insert(r.id) }
                                else { selectedIDs.remove(r.id) }
                            }
                        ))
                        .labelsHidden()
                    }
                }
                .width(showSelection ? 40 : 0) // 如果不顯示，寬度設為 0 或隱藏
                
                TableColumn("GSX 單號", value: \.gsxID) { r in
                    Text(r.gsxID)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) { onCopy(r.gsxID) }
                        .contextMenu { Button("複製單號") { onCopy(r.gsxID) } }
                        .help("雙擊複製 GSX 單號")
                }
                .width(min: 120)
                
                TableColumn("RMA 單號", value: \.rmaID) { r in
                    Text(r.rmaID)
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) { onCopy(r.rmaID) }
                        .contextMenu { Button("複製 RMA") { onCopy(r.rmaID) } }
                        .help("雙擊複製 RMA 單號")
                }
                .width(min: 120)
                
                TableColumn("SA 狀態", value: \.saStatus) { r in
                    Text(r.saStatus)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(r.isAnomaly ? Color.orange.opacity(0.2) : Color.clear)
                        .foregroundStyle(r.isAnomaly ? .orange : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .width(min: 100)
                
                TableColumn("GSX 狀態", value: \.gsxStatus) { r in
                    Text(r.gsxStatus)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .width(min: 150)
                
                TableColumn("異常") { r in
                    if r.isAnomaly {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red.opacity(0.8))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green.opacity(0.5))
                    }
                }
                .width(50)
            }
            .onChange(of: sortOrder) { _, _ in }
            .scrollContentBackground(.hidden)
        }
    }
}
