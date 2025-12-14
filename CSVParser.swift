import Foundation

struct CSVParser {
    static func readFileContent(url: URL) -> String? {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        if let str = String(data: data, encoding: .utf8) { return str }
        if let str = String(data: data, encoding: .utf16) { return str }
        let big5 = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.big5.rawValue))
        if let str = String(data: data, encoding: String.Encoding(rawValue: big5)) { return str }
        if let str = String(data: data, encoding: .windowsCP1252) { return str }
        return nil
    }
    
    static func parse(url: URL) -> (headers: [String], rows: [[String: String]], rawLog: String)? {
        guard var content = readFileContent(url: url) else { return nil }
        content = content.replacingOccurrences(of: "\u{FEFF}", with: "")
        
        var lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        var headerIndex = 0
        var foundHeader = false
        for (index, line) in lines.enumerated() {
            if line.contains("採購") || line.contains("Purchase") || line.contains("單號") || line.contains("Order") || line.contains("Status") {
                headerIndex = index
                foundHeader = true
                break
            }
        }
        if !foundHeader { headerIndex = 0 }
        
        let headerLine = lines[headerIndex]
        let delimiter = headerLine.contains("\t") ? "\t" : ","
        
        func clean(_ str: String) -> String {
            return str.replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        let headers = headerLine.components(separatedBy: delimiter).map { clean($0) }
        var result: [[String: String]] = []
        
        for i in (headerIndex + 1)..<lines.count {
            let values = lines[i].components(separatedBy: delimiter).map { clean($0) }
            if values.count > 1 {
                var dict: [String: String] = [:]
                for (index, header) in headers.enumerated() {
                    if index < values.count {
                        dict[header] = values[index]
                    }
                }
                result.append(dict)
            }
        }
        return (headers, result, rawLog: "讀取成功")
    }
}
