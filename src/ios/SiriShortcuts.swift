import Intents
import IntentsUI

@objc(SiriShortcuts) class SiriShortcuts : CDVPlugin {
    @available(iOS 12.0, *)
    typealias GetVoiceShortcut = (INVoiceShortcut?) -> Void

    var activity: NSUserActivity?
    var shortcutPresentedDelegate: ShortcutPresentedDelegate?
    var shortcutEditPresentedDelegate: ShortcutEditPresentedDelegate?

    public static func getActivityName() -> String? {
        guard let identifier = Bundle.main.bundleIdentifier else { return nil }

        // corresponds to the NSUserActivityTypes
        let activityName = identifier + ".shortcut"

        return activityName
    }

    @objc(donate:) func donate(_ command: CDVInvokedUrlCommand) {
        self.commandDelegate!.run(inBackground: {
            if #available(iOS 12.0, *) {
                self.activity = self.createUserActivity(from: command, makeActive: true)

                // tell Cordova we're all OK
                self.sendStatusOk(command)

                return
            }

            // shortcut not donated
            self.sendStatusError(command)
        })
    }

    @objc(present:) func present(_ command: CDVInvokedUrlCommand) {
        self.commandDelegate!.run(inBackground: {
            if #available(iOS 12.0, *) {
                guard let persistentIdentifier = command.arguments[0] as? String else {
                    self.sendStatusError(command, error: ShortcutResponseCode.noPersistentIdentifier.rawValue)
                    return
                }

                self.getVoiceShortcut( persistentIdentifier: persistentIdentifier, completion: {[unowned self] inVoiceShortcut in
                        if let inVS = inVoiceShortcut{
                            
                            self.shortcutEditPresentedDelegate = ShortcutEditPresentedDelegate(command: command, shortcuts: self)
                            
                            let viewController = INUIEditVoiceShortcutViewController(voiceShortcut: inVS)
                            viewController.delegate = self.shortcutEditPresentedDelegate!
                            
                            DispatchQueue.main.async {
                                self.viewController?.present(viewController, animated: true, completion: nil)
                            }
                            
                            return
                            
                        }
                        else{
                            self.activity = self.createUserActivity(from: command, makeActive: false)
                            
                            if self.activity != nil {
                                self.shortcutPresentedDelegate = ShortcutPresentedDelegate(command: command, shortcuts: self)
                                
                                let shortcut = INShortcut(userActivity: self.activity!)
                                
                                let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
                                viewController.delegate = self.shortcutPresentedDelegate!
                                
                                DispatchQueue.main.async {
                                    self.viewController?.present(viewController, animated: true, completion: nil)
                                }
                                
                                // tell Cordova we're all OK
                                //self.sendStatusOk(command)
                                
                                return
                            }
                            
                            self.sendStatusError(command)
                            
                            return
                        }
                    
                    }
                )
            }
            else{
                // shortcut not donated
                self.sendStatusError(command)
            }
            
        })
    }

    @objc(remove:) func remove(_ command: CDVInvokedUrlCommand) {
        self.commandDelegate!.run(inBackground: {
            if #available(iOS 12.0, *) {
                // convert all string values to objects, such that they can be removed
                guard let stringIdentifiers = command.arguments[0] as? [String] else { return }
                var persistentIdentifiers: [NSUserActivityPersistentIdentifier] = []

                for stringIdentifier in stringIdentifiers {
                    persistentIdentifiers.append(NSUserActivityPersistentIdentifier(stringIdentifier))
                }

                NSUserActivity.deleteSavedUserActivities(withPersistentIdentifiers: persistentIdentifiers, completionHandler: {
                    self.sendStatusOk(command)
                })
            } else {
                self.sendStatusError(command)
            }
        })
    }

    @objc(removeAll:) func removeAll(_ command: CDVInvokedUrlCommand) {
        self.commandDelegate!.run(inBackground: {
            if #available(iOS 12.0, *) {
                NSUserActivity.deleteAllSavedUserActivities(completionHandler: {
                    self.sendStatusOk(command)
                })
            } else {
                self.sendStatusError(command)
            }
        })
    }
    
    @objc(getActivatedShortcut:) func getActivatedShortcut(_ command: CDVInvokedUrlCommand) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        self.commandDelegate!.run(inBackground: {
            if #available(iOS 12.0, *) {

                if let userActivity = appDelegate.userActivity {
                    let title = userActivity.title
                    var userInfo = userActivity.userInfo ?? [:]
                    let persistentIdentifier = userInfo["persistentIdentifier"]

                    userInfo.removeValue(forKey: "persistentIdentifier")

                    let returnData = [
                        "title": title,
                        "persistentIdentifier": persistentIdentifier,
                        "userInfo": userInfo,
                    ]

                    let clear = command.arguments[0] as? Bool ?? true
                    if clear {
                        appDelegate.userActivity = nil
                    }
                    
                    self.sendStatusOk(command, responseMessage: returnData)
                    return
                }
                self.sendStatusOk(command)
                
            } else {
                self.sendStatusError(command)
            }
        })
    }
    

    func createUserActivity(from command: CDVInvokedUrlCommand, makeActive: Bool) -> NSUserActivity? {
        if #available(iOS 12.0, *) {
            // corresponds to the NSUserActivityTypes
            guard let activityName = SiriShortcuts.getActivityName() else { return nil }

            // extract all features
            guard let persistentIdentifier = command.arguments[0] as? String else { return nil }
            guard let title = command.arguments[1] as? String else { return nil }
            let suggestedInvocationPhrase = command.arguments[2] as? String
            var userInfo = command.arguments[3] as? [String: Any] ?? [:]

            var isEligibleForSearch = true
            var isEligibleForPrediction = true

            if command.arguments.count > 5 {
                isEligibleForSearch = command.arguments[4] as? Bool ?? true
                isEligibleForPrediction = command.arguments[5] as? Bool ?? true
            }

            userInfo["persistentIdentifier"] = persistentIdentifier

            // create shortcut
            let activity = NSUserActivity(activityType: activityName)
            activity.title = title
            activity.suggestedInvocationPhrase = suggestedInvocationPhrase
            activity.persistentIdentifier = NSUserActivityPersistentIdentifier(persistentIdentifier)
            activity.isEligibleForSearch = isEligibleForSearch
            activity.isEligibleForPrediction = isEligibleForPrediction

            if (makeActive) {
                ActivityDataHolder.setUserInfo(userInfo)

                activity.needsSave = true

                // donate shortcut
                self.viewController?.userActivity = activity
            } else {
                activity.userInfo = userInfo
            }

            return activity
        } else {
            return nil
        }
    }

    @objc(getAll:) func getAll(_ command: CDVInvokedUrlCommand) {
        self.commandDelegate!.run(inBackground: {
            if #available(iOS 12.0, *) {
                INVoiceShortcutCenter.shared.getAllVoiceShortcuts{ [unowned self] (voiceShortcutsFromCenter, error) in
                    if let voiceShortcutsFromCenter = voiceShortcutsFromCenter {
                        var persistentIdentifierList = [[AnyHashable: Any]]()
                        for vShortcut in voiceShortcutsFromCenter{
                            if let act:NSUserActivity = vShortcut.shortcut.userActivity,
                                let ui = act.userInfo, let pi = ui["persistentIdentifier"]{
                                let piData = [
                                    "persistentIdentifier": pi as! String,
                                    "invocationPhrase": vShortcut.invocationPhrase,
                                    ]
                                persistentIdentifierList.append(piData)
                                
                            }
                        }
                        let pluginResult = CDVPluginResult(
                            status: CDVCommandStatus_OK,
                            messageAs: persistentIdentifierList
                        )
                        
                        self.send(pluginResult: pluginResult!, command: command)
                        return
                    }

                    self.sendStatusOk(command)
                }
            }
            else {
                self.sendStatusError(command)
            }
        })
    }

    @available(iOS 12.0, *)
    func getVoiceShortcut(persistentIdentifier: String, completion: @escaping GetVoiceShortcut) {
        var voiceShortcut:INVoiceShortcut?
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts{ (voiceShortcutsFromCenter, error) in
            if let voiceShortcutsFromCenter = voiceShortcutsFromCenter {
                for vShortcut in voiceShortcutsFromCenter{
                    if let act:NSUserActivity = vShortcut.shortcut.userActivity,
                        let ui = act.userInfo, let pi = ui["persistentIdentifier"]{
                        debugPrint(pi as! String)
                        if persistentIdentifier == pi as! String{
                            voiceShortcut = vShortcut
                            debugPrint(voiceShortcutsFromCenter)
                            break
                        }
                    }
                }
                
            } else {
                if let error = error as NSError? {
                    debugPrint("Failed to fetch voice shortcuts with error: \(error.localizedDescription)")
                }
            }
            
             completion(voiceShortcut)
        }
    }

    func sendStatusOk(_ command: CDVInvokedUrlCommand) {
        self.send(status: CDVCommandStatus_OK, command: command)
    }

    func sendStatusOk(_ command: CDVInvokedUrlCommand, responseMessage: [AnyHashable: Any]) {
        
        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: responseMessage
        )
        
        self.send(pluginResult: pluginResult!, command: command)
    }

    func sendStatusError(_ command: CDVInvokedUrlCommand, error: String? = nil) {
        var message = error

        if message == nil {
            message = ShortcutResponseCode.noIos12.rawValue
        }

        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR,
            messageAs: message
        )

        self.send(pluginResult: pluginResult!, command: command)
    }

    func send(status: CDVCommandStatus, command: CDVInvokedUrlCommand) {
        let pluginResult = CDVPluginResult(
            status: status
        )

        self.send(pluginResult: pluginResult!, command: command)
    }

    func send(pluginResult: CDVPluginResult, command: CDVInvokedUrlCommand) {
        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )
    }
}
