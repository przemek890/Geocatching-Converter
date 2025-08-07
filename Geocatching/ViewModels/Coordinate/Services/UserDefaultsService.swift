import Foundation

protocol UserDefaultsServiceProtocol {
    func save<T>(_ value: T, forKey key: String)
    func load<T>(forKey key: String, type: T.Type) -> T?
    func loadString(forKey key: String) -> String?
    func synchronize()
}

class UserDefaultsService: UserDefaultsServiceProtocol {
    private let userDefaults = UserDefaults.standard
    
    func save<T>(_ value: T, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func load<T>(forKey key: String, type: T.Type) -> T? {
        return userDefaults.object(forKey: key) as? T
    }
    
    func loadString(forKey key: String) -> String? {
        return userDefaults.string(forKey: key)
    }
    
    func synchronize() {
        userDefaults.synchronize()
    }
}
