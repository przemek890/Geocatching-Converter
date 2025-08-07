import Foundation

struct Alphabets {
    static let english = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map(String.init)
    static let polish = Array("AĄBCĆDEĘFGHIJKLŁMNŃOÓPQRSŚTUVWXYZŹŻ").map(String.init)
    
    static func getCurrent(for type: String) -> [String] {
        return type == "polish" ? polish : english
    }
}