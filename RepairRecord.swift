import Foundation

struct RepairRecord: Identifiable, Hashable {
    let id: UUID
    let gsxID: String
    let rmaID: String
    let saStatus: String
    let gsxStatus: String
    let date: String
    let isAnomaly: Bool
    
    init(id: UUID = UUID(), gsxID: String, rmaID: String, saStatus: String, gsxStatus: String, date: String, isAnomaly: Bool) {
        self.id = id
        self.gsxID = gsxID
        self.rmaID = rmaID
        self.saStatus = saStatus
        self.gsxStatus = gsxStatus
        self.date = date
        self.isAnomaly = isAnomaly
    }
}
