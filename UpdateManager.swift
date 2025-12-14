import Foundation
import Combine
import SwiftUI

// 1. 定義 GitHub 回傳的資料結構
struct GitHubRelease: Codable {
    let tagName: String
    let htmlUrl: String
    let body: String // 這是你的更新日誌 (Release Notes)

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlUrl = "html_url"
        case body
    }
}

// 2. 更新管理器
@MainActor
class UpdateManager: ObservableObject {
    private let userName = "hsiao840412"
    private let repoName = "GSX-Status-Check"
    
    @Published var hasUpdate: Bool = false
    @Published var latestVersion: String = ""
    @Published var releaseURL: URL?
    @Published var releaseNotes: String = ""
    
    // 獲取目前 App 的版本 (從 Info.plist 讀取)
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    func checkForUpdates() {
        guard let url = URL(string: "https://api.github.com/repos/\(userName)/\(repoName)/releases/latest") else { return }
        
        print("🔍 正在檢查更新: \(url.absoluteString)")
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                
                // 處理版本號：把 "v" 去掉以便比較 (例如 v4.5 -> 4.5)
                let serverVer = release.tagName.replacingOccurrences(of: "v", with: "")
                let localVer = currentVersion.replacingOccurrences(of: "v", with: "")
                
                print("📝 本地版本: \(localVer), 伺服器版本: \(serverVer)")
                
                // 版本比較邏輯 (如果伺服器版本 > 本地版本)
                if serverVer.compare(localVer, options: .numeric) == .orderedDescending {
                    self.latestVersion = release.tagName
                    self.releaseURL = URL(string: release.htmlUrl)
                    self.releaseNotes = release.body
                    self.hasUpdate = true
                    print("✅ 發現新版本！")
                } else {
                    print("✅ 目前已是最新版本")
                }
            } catch {
                print("❌ 檢查更新失敗: \(error.localizedDescription)")
            }
        }
    }
}
