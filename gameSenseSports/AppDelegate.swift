//
//  AppDelegate.swift
//  gameSenseSports
//
//  Created by Ra on 11/15/16.
//  Copyright © 2016 gameSenseSports. All rights reserved.
//

import UIKit
import CoreData
import SystemConfiguration

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var _apiToken: String = ""
    public var apiToken : String
    {
        set(value)
        {
            _apiToken = value
        }
        get {
            return _apiToken
        }
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let config: RollbarConfiguration = RollbarConfiguration()
        config.environment = "production"
        
        Rollbar.initWithAccessToken("3b7e8110851641b9898b93abf2ef0fa0", configuration: config)
        
        let gai = GAI.sharedInstance()
        gai?.tracker(withTrackingId: "UA-76645768-2")
        // Optional: automatically report uncaught exceptions.
        gai?.trackUncaughtExceptions = true
        
        // Optional: set Logger to VERBOSE for debug information.
        // Remove before app release.
        gai?.logger.logLevel = .verbose;
        
        let cacheDirectory = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileManager =  FileManager.default
        let files = try! fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil, options: [])
        var folderFileSizeInBytes = 0
        for file in files {
            folderFileSizeInBytes +=  try! (fileManager.attributesOfItem(atPath: file.path) as NSDictionary).fileSize().hashValue
        }
        // format it using NSByteCountFormatter to display it properly
        let  byteCountFormatter =  ByteCountFormatter()
        byteCountFormatter.allowedUnits = .useBytes
        byteCountFormatter.countStyle = .file
        
        if (Int64(folderFileSizeInBytes) > 150000000 || self.deviceRemainingFreeSpaceInBytes()! < 150000000)
        {
            for file in files {
                try? fileManager.removeItem(at: file)
            }
        }
        
        // Check for initial cache and create if unavailable
        if (UserDefaults.standard.object(forKey: Constants.kCacheKey) == nil && isConnectedToNetwork())
        {
            SharedNetworkConnection.downloadCache(completionHandler: { data, response, error in
                guard let data = data, error == nil else {                                                 // check for fundamental networking error
                    print("error=\(error)")
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                    // 403 on no token
                    print("statusCode should be 200, but is \(httpStatus.statusCode)")
                    print("response = \(response)")
                }
                try? data.write(to: cacheDirectory.appendingPathComponent("cache.zip"))
                // Unzip
                SSZipArchive.unzipFile(atPath: cacheDirectory.appendingPathComponent("cache.zip").path, toDestination: cacheDirectory.path)
                try? fileManager.removeItem(at: cacheDirectory.appendingPathComponent("cache.zip"))
                UserDefaults.standard.set(true, forKey: Constants.kCacheKey)
            })
        }
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        // Access the storyboard and fetch an instance of the view controller
        let data = url.absoluteString.components(separatedBy: "#")[1]
        let drillData = NSData(base64Encoded: data, options: NSData.Base64DecodingOptions())
        let json = (try? JSONSerialization.jsonObject(with: drillData! as Data, options: [])) as! [String: Any]
        let drill = DrillListItem(json: json)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginController: LoginViewController = storyboard.instantiateViewController(withIdentifier: "login") as! LoginViewController
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = loginController
        self.window?.makeKeyAndVisible()
        if self.apiToken != "" {
            let videoPlayerViewController: VideoPlayerViewController = storyboard.instantiateViewController(withIdentifier: "videoplayer") as! VideoPlayerViewController;
            //        let drillListViewController: DrillListViewController = storyboard.instantiateViewController(withIdentifier: "drilllist") as! DrillListViewController
            let navController = storyboard.instantiateViewController(withIdentifier: "drilllistnav") as! UINavigationController
            let drillListViewController: DrillListViewController = navController.viewControllers[0] as! DrillListViewController
            
            drillListViewController.selectedDrillItem = drill!
            navController.pushViewController(videoPlayerViewController, animated: false)
            loginController.present(navController, animated: true, completion: nil)
        }
        // Then push that view controller onto the navigation stack
//        let rootViewController = self.window!.rootViewController as! UINavigationController;
//        rootViewController.pushViewController(viewController, animated: true);
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        // self.saveContext()
    }

    // MARK: - Core Data stack
/*
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "gameSenseSports")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    */
    func deviceRemainingFreeSpaceInBytes() -> Int64? {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
        guard
            let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: documentDirectory),
            let freeSize = systemAttributes[.systemFreeSize] as? NSNumber
            else {
                // something failed
                return nil
        }
        return freeSize.int64Value
    }
    
    func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        let isReachable = flags == .reachable
        let needsConnection = flags == .connectionRequired
        
        
        
        return isReachable && !needsConnection
    }
}

