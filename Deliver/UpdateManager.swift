import Foundation
import Combine
import Sparkle

final class UpdateManager: NSObject, ObservableObject {
    private let updaterController: SPUStandardUpdaterController
    
    override init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        
        super.init()
    }
    
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}
