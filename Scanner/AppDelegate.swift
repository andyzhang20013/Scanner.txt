//
//  AppDelegate.swift
//  Scanner
//
//  Created by Andy Zhang on 5/27/20.
//  Copyright © 2020 Andy Zhang. All rights reserved.
//

import UIKit
import RealmSwift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var launchedShortcutItem: UIApplicationShortcutItem?
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        
        
        print(Realm.Configuration.defaultConfiguration.fileURL) //location of Realm Database
        
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem{
            launchedShortcutItem = shortcutItem
        }
        
        
        do{
             let realm = try Realm()
            
        }
        catch{
            print("Error initializing Realm: \(error)")
        }
        return true
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handleShortcutItem(item: shortcutItem))
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        
        guard let shortcutItem = launchedShortcutItem else { return }
        //If there is any shortcutItem,that will be handled upon the app becomes active
        _ = handleShortcutItem(item: shortcutItem)
        //We make it nil after perfom/handle method call for that shortcutItem action
        launchedShortcutItem = nil
        /*
        if let shortcutItem = launchedShortcutItem {
            // In this sample an alert is being shown to indicate that the action has been triggered,
            // but in real code the functionality for the quick action would be triggered.
            let mainStoryboard = UIStoryboard.init(name: "Main", bundle: Bundle.main)
            var reqVC: UIViewController!
            reqVC = mainStoryboard.instantiateViewController(withIdentifier: "ProcessedImageViewController") as! ProcessedImageViewController
            
            if let homeVC = self.window?.rootViewController as? UINavigationController {
                homeVC.pushViewController(reqVC, animated: true)
            }
            // Reset the shortcut item so it's never processed twice.
            launchedShortcutItem = nil
        }*/
    }
    
    /*func handleShortcutItem(item: UIApplicationShortcutItem) -> Bool {
        var handled = false
        //guard ShortcutIdentifier(fullNameForType: item.type) != nil else {return false}
        guard let shortCutType = item.type as String? else {return false}
        let mainStoryboard = UIStoryboard.init(name: "Main", bundle: Bundle.main)
        var reqVC: UIViewController!
        if let homeVC = self.window?.rootViewController as? UINavigationItem{
            home.pushViewController(reqVC, animated: true)
        }
        else {
            return false
        }
        
        return handled
    }*/
    func handleShortcutItem(item: UIApplicationShortcutItem) -> Bool {
        var handled = false
        // Verify that the provided shortcutItem's type is one handled by the application.
        let mainStoryboard = UIStoryboard.init(name: "Main", bundle: Bundle.main)
        var reqVC: UIViewController!
        reqVC = mainStoryboard.instantiateViewController(withIdentifier: "ProcessedImageViewController") as! ProcessedImageViewController
        handled = true
        if let homeVC = self.window?.rootViewController as? UINavigationController {
            homeVC.pushViewController(reqVC, animated: true)
        } else {
            return false
        }
        
        return handled
    }
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

