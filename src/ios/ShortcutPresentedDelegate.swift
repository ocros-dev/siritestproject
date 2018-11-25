import Intents
import IntentsUI

class ShortcutPresentedDelegate: NSObject, INUIAddVoiceShortcutViewControllerDelegate {
    let command: CDVInvokedUrlCommand
    let shortcuts: SiriShortcuts

    init(command: CDVInvokedUrlCommand, shortcuts: SiriShortcuts) {
        self.command = command
        self.shortcuts = shortcuts
    }

    @available(iOS 12.0, *)
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController,
                                        didFinishWith voiceShortcut: INVoiceShortcut?,
                                        error: Error?) {
        if let err = error as NSError? {
            debugPrint(err)
            self.shortcuts.sendStatusError(self.command, error: ShortcutResponseCode.internalError.rawValue)
            return
        }

        self.shortcuts.sendStatusOk(self.command, codeMessage: ShortcutResponseCode.created.rawValue)

        controller.dismiss(animated: true)
    }

    @available(iOS 12.0, *)
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        self.shortcuts.sendStatusError(self.command, error: ShortcutResponseCode.dismiss.rawValue)

        controller.dismiss(animated: true)
    }
}

class ShortcutEditPresentedDelegate: NSObject, INUIEditVoiceShortcutViewControllerDelegate{
    let command: CDVInvokedUrlCommand
    let shortcuts: SiriShortcuts
    
    init(command: CDVInvokedUrlCommand, shortcuts: SiriShortcuts) {
        self.command = command
        self.shortcuts = shortcuts
    }
    
    @available(iOS 12.0, *)
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        if let err = error as NSError? {

            self.shortcuts.sendStatusError(self.command, error: ShortcutResponseCode.internalError.rawValue)
            return
        }
        
        self.shortcuts.sendStatusOk(self.command, codeMessage: ShortcutResponseCode.modified.rawValue)
        controller.dismiss(animated: true, completion: nil)
    }
    
    @available(iOS 12.0, *)
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        self.shortcuts.sendStatusOk(self.command, codeMessage: ShortcutResponseCode.deleted.rawValue)
        controller.dismiss(animated: true, completion: nil)
    }
    
    @available(iOS 12.0, *)
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        self.shortcuts.sendStatusError(self.command, error: ShortcutResponseCode.dismiss.rawValue)
        controller.dismiss(animated: true, completion: nil)
    }
    
}