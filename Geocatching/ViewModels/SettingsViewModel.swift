import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("defaultInputFormat") var defaultInputFormat = CoordinateFormat.dd.rawValue
    @AppStorage("defaultOutputFormat") var defaultOutputFormat = CoordinateFormat.dms.rawValue
    @AppStorage("defaultMapService") var defaultMapService = "apple"
    @AppStorage("lockDigits") var lockDigits = 4
    @AppStorage("lockEnteredLetters") var lockEnteredLetters: String = ""
    
    func toggleDarkMode() {
        isDarkMode.toggle()
    }
    
    func setInputFormat(_ format: CoordinateFormat) {
        defaultInputFormat = format.rawValue
    }
    
    func setOutputFormat(_ format: CoordinateFormat) {
        defaultOutputFormat = format.rawValue
    }
    
    func setMapService(_ service: String) {
        defaultMapService = service
    }
    
    func setLockDigits(_ digits: Int) {
        lockDigits = digits
    }
}
