import Foundation
import CryptoKit
import LocalAuthentication

// MARK: - Security Manager
@MainActor
class SecurityManager: ObservableObject {
    static let shared = SecurityManager()
    
    @Published var isAuthenticated = false
    @Published var isBiometricEnabled = false
    
    private var masterKey: SymmetricKey?
    private let context = LAContext()
    
    private init() {
        setupMasterKey()
        checkBiometricAvailability()
    }
    
    private func setupMasterKey() {
        if let existingKey = loadKey(identifier: "master_key") {
            masterKey = existingKey
        } else {
            let newKey = SymmetricKey(size: .bits256)
            saveKey(newKey, identifier: "master_key")
            masterKey = newKey
        }
    }
    
    private func checkBiometricAvailability() {
        var error: NSError?
        isBiometricEnabled = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    // MARK: - Authentication
    func authenticateUser(password: String? = nil) async throws -> Bool {
        if isBiometricEnabled {
            let reason = "请使用生物识别验证身份"
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            isAuthenticated = success
            return success
        }
        
        // 简化的密码验证
        if let password = password, !password.isEmpty {
            isAuthenticated = true
            return true
        }
        
        return false
    }
    
    // MARK: - Data Encryption
    func encryptData(_ data: String) throws -> EncryptedData {
        guard let key = masterKey else {
            throw SecurityError.keyNotFound
        }
        
        let dataToEncrypt = data.data(using: .utf8)!
        let sealedBox = try AES.GCM.seal(dataToEncrypt, using: key)
        
        return EncryptedData(
            data: sealedBox.ciphertext.base64EncodedString(),
            iv: sealedBox.nonce.withUnsafeBytes { Data($0) }.base64EncodedString(),
            salt: "",
            algorithm: "AES-256-GCM",
            timestamp: Date()
        )
    }
    
    func decryptData(_ encryptedData: EncryptedData) throws -> String {
        guard let key = masterKey else {
            throw SecurityError.keyNotFound
        }
        
        guard let ciphertext = Data(base64Encoded: encryptedData.data),
              let nonceData = Data(base64Encoded: encryptedData.iv),
              let nonce = try? AES.GCM.Nonce(data: nonceData) else {
            throw SecurityError.decryptionFailed
        }
        
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: Data())
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw SecurityError.decryptionFailed
        }
        
        return decryptedString
    }
    
    // MARK: - Key Management
    func storeSecureKey(_ key: String, value: String) throws {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw SecurityError.encryptionFailed
        }
    }
    
    func getSecureKey(_ key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    func deleteSecureKey(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    private func saveKey(_ key: SymmetricKey, identifier: String) {
        let keyData = key.withUnsafeBytes { Data($0) }
        try? storeSecureKey(identifier, value: keyData.base64EncodedString())
    }
    
    private func loadKey(identifier: String) -> SymmetricKey? {
        guard let keyString = try? getSecureKey(identifier),
              let keyData = Data(base64Encoded: keyString) else {
            return nil
        }
        return SymmetricKey(data: keyData)
    }
}

// MARK: - Security Error
enum SecurityError: Error {
    case keyNotFound
    case encryptionFailed
    case decryptionFailed
}

// MARK: - Encrypted Data
struct EncryptedData: Codable {
    let data: String
    let iv: String
    let salt: String
    let algorithm: String
    let timestamp: Date
}