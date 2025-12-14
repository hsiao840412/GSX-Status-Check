import SwiftUI
import AppKit
import UniformTypeIdentifiers

// 1. 玻璃檔案選擇器
struct GlassFilePicker: View {
    let title: String
    let icon: String
    @Binding var path: String
    var isDragging: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.7))
            
            HStack {
                Text(path.isEmpty ? "請選擇或拖入檔案..." : URL(string: path)?.lastPathComponent ?? path)
                    .font(.system(size: 13))
                    .foregroundStyle(path.isEmpty ? .white.opacity(0.3) : .white)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button("瀏覽") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.allowedContentTypes = [.item]
                    if panel.runModal() == .OK { path = panel.url?.absoluteString ?? "" }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.white)
            }
            .padding(10)
            .background(isDragging ? Color.blue.opacity(0.3) : Color.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isDragging ? Color.blue : Color.white.opacity(0.1), lineWidth: isDragging ? 2 : 1)
            )
            .animation(.easeInOut, value: isDragging)
        }
    }
}

// 2. 玻璃分頁按鈕
struct GlassTab: View {
    let title: String
    let count: Int
    let idx: Int
    @Binding var sel: Int
    let color: Color
    
    var isSelected: Bool { sel == idx }
    
    var body: some View {
        Button(action: { withAnimation { sel = idx } }) {
            HStack(spacing: 8) {
                Text(title)
                    .fontWeight(isSelected ? .bold : .regular)
                
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white : Color.white.opacity(0.1))
                    .foregroundStyle(isSelected ? color : .white)
                    .clipShape(Capsule())
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                isSelected ?
                LinearGradient(colors: [color.opacity(0.8), color.opacity(0.5)], startPoint: .top, endPoint: .bottom) :
                LinearGradient(colors: [Color.clear, Color.clear], startPoint: .top, endPoint: .bottom)
            )
            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// 3. 功能按鈕
struct ActionButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    var isHighlight: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.system(size: 12, weight: .medium))
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                isHighlight ?
                (isActive ? Color.green.opacity(0.8) : Color.gray.opacity(0.3)) :
                Color.white.opacity(0.1)
            )
            .foregroundStyle(isActive ? .white : .white.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(isActive ? 0.3 : 0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// 4. 浮動通知氣泡
struct GlassToast: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                .font(.title3)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.4))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.1)], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}
