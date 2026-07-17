import Foundation

var sessionStatus: Bool = false

let sessionExpirationKey = "sessionExpiration"

@discardableResult
func sessionLoginStatus(status: Bool) -> Bool {
    sessionStatus = status

    if status {
        let expirationDate = Date().addingTimeInterval(86400)
        UserDefaults.standard.set(expirationDate, forKey: sessionExpirationKey)
    } else {
        UserDefaults.standard.removeObject(forKey: sessionExpirationKey)
    }

    return sessionStatus
}

func restoreSession() -> Bool {
    guard let expirationDate = UserDefaults.standard.object(
        forKey: sessionExpirationKey
    ) as? Date else {
        sessionStatus = false
        return false
    }

    if Date() < expirationDate {
        sessionStatus = true
        return true
    } else {
        sessionStatus = false
        UserDefaults.standard.removeObject(forKey: sessionExpirationKey)
        return false
    }
}
