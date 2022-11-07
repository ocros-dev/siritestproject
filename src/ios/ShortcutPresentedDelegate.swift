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

        let returnData = ["code": ShortcutResponseCode.created.rawValue,
                                "message" : ShortcutResponseCode.created.description,
                                "phrase" : voiceShortcut?.invocationPhrase ?? ""]

        self.shortcuts.sendStatusOk(self.command, responseMessage: returnData)

        controller.dismiss(animated: true)
    }

    @available(iOS 12.0, *)
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        let returnData = ["code": ShortcutResponseCode.dismiss.rawValue,
                          "message" : ShortcutResponseCode.dismiss.description,
                          "phrase" : ""]
        self.shortcuts.sendStatusOk(self.command, responseMessage: returnData)

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
            debugPrint(err)
            self.shortcuts.sendStatusError(self.command, error: ShortcutResponseCode.internalError.rawValue)
            return
        }
        
        let returnData = ["code": ShortcutResponseCode.modified.rawValue,
                                "message" : ShortcutResponseCode.modified.description,
                                "phrase" : voiceShortcut?.invocationPhrase ?? ""]

        self.shortcuts.sendStatusOk(self.command, responseMessage: returnData)

        controller.dismiss(animated: true, completion: nil)
    }
    
    @available(iOS 12.0, *)
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        let returnData = ["code": ShortcutResponseCode.deleted.rawValue,
                                "message" : ShortcutResponseCode.deleted.description,
                                "phrase" : ""]

        self.shortcuts.sendStatusOk(self.command, responseMessage: returnData)

        controller.dismiss(animated: true, completion: nil)
    }
    
    @available(iOS 12.0, *)
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        let returnData = ["code": ShortcutResponseCode.dismiss.rawValue,
                          "message" : ShortcutResponseCode.dismiss.description,
                          "phrase" : ""]
        self.shortcuts.sendStatusOk(self.command, responseMessage: returnData)
        
        controller.dismiss(animated: true, completion: nil)
    }
    
}