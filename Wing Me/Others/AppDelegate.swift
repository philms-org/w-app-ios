
import UIKit
import CoreData
import GoogleMaps
import FBSDKCoreKit
import FirebaseCore
import CoreLocation
import FirebaseMessaging
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var array: [CustomCell] = []
    
    var window: UIWindow?
    var locationManager: CLLocationManager?
    
    var setInbox: ((_ userID: String, _ message: String, _ date: String) -> ())?
    var setGroup: ((_ groupID: String, _ message: String, _ date: String) -> ())?
    var setChatMessage: ((_ messageID: String, _ message: String, _ date: String) -> ())?
    var setGroupChatMessage: ((_ messageID: String, _ userName: String, _ gender: String, _ message: String, _ date: String) -> ())?
    var setLastMessage: ((_ userID: String, _ message: String, _ date: String) -> ())?
    var setLastGroupMessage: ((_ userID: String, _ message: String, _ date: String) -> ())?
    
    var reloadLocation: (() -> ())?
    var reloadMessages: (() -> ())?
    var reloadGroups: (() -> ())?
    var reloadChat: (() -> ())?
    var reloadGroup: (() -> ())?
    
    var firebaseToken = String()
    var userID = String()
    var groupID = String()
    var longitude = Double()
    var latitude = Double()
    var isBackground = Bool()
    var inLocation = Bool()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        inLocation = false
        
        GMSServices.provideAPIKey(MapStyle.key)
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound], completionHandler: {
            _, _ in
            
        })
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        let decoder = PropertyListDecoder()
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let url = directory.appendingPathComponent("SavedImages").appendingPathExtension("plist")
        if let file = try? Data(contentsOf: url), let decodedProduct = try? decoder.decode([String: String].self, from: file) {
            Constants.savedImages = decodedProduct
        }
        application.registerForRemoteNotifications()
        FirebaseApp.configure()
        return true
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if let launchOptions = launchOptions, let _ = launchOptions[UIApplication.LaunchOptionsKey.location] {
            guard let _ = UserDefaults.standard.object(forKey: "Token") else {
                return true
            }
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            
            getLocations()
        }
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        isBackground = false
        
        if let reloadMessages = reloadMessages {
            reloadMessages()
        }
        if let reloadChat = reloadChat {
            reloadChat()
        }
        if let reloadGroups = reloadGroups {
            reloadGroups()
        }
        if let reloadGroup = reloadGroup {
            reloadGroup()
        }
        getToken()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        isBackground = true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        saveContext()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        saveImages()
        
        guard let _ = UserDefaults.standard.object(forKey: "Token") else {
            return
        }
        locationManager = CLLocationManager()
        locationManager?.stopUpdatingLocation()
        locationManager?.startMonitoringSignificantLocationChanges()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let content = notification.request.content
        let userInfo = content.userInfo
        
        if let data = try? JSONSerialization.data(withJSONObject: userInfo), let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary {
            
            print(jsonObject)
            
            if let setChatMessage = setChatMessage {
                let user_Id = jsonObject.getString(key: "user_Id")
                
                if user_Id == userID {
                    let message_Id = jsonObject.getString(key: "message_Id")
                    let message = jsonObject.getString(key: "message")
                    let date = jsonObject.getString(key: "date")
                    setChatMessage(message_Id, message, date)
                    return
                }
            } else if let setGroupChatMessage = setGroupChatMessage {
                let comment_Id = jsonObject.getString(key: "comment_Id")
                
                if comment_Id == groupID {
                    let message_Id = jsonObject.getString(key: "message_Id")
                    let user_name = jsonObject.getString(key: "user_name")
                    let gender = jsonObject.getString(key: "gender")
                    let message = jsonObject.getString(key: "message")
                    let date = jsonObject.getString(key: "date")
                    setGroupChatMessage(message_Id, user_name, gender, message, date)
                    return
                }
            }
            if let setInbox = setInbox {
                let user_Id = jsonObject.getString(key: "user_Id")
                let message = jsonObject.getString(key: "message")
                let date = jsonObject.getString(key: "date")
                setInbox(user_Id, message, date)
            }
            if let setGroup = setGroup {
                let comment_Id = jsonObject.getString(key: "comment_Id")
                let message = jsonObject.getString(key: "message")
                let date = jsonObject.getString(key: "date")
                setGroup(comment_Id, message, date)
            }
        }
        completionHandler([.banner, .list, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let content = response.notification.request.content
        let userInfo = content.userInfo
        
        if let data = try? JSONSerialization.data(withJSONObject: userInfo), let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary {
            
            print(jsonObject)
            
            let category = jsonObject.getString(key: "click_action")
            
            guard let currentVC = getCurrentVC() else {
                return
            }
            if category == "open_inbox" {
                let user_Id = jsonObject.getString(key: "user_Id")
                openChat(delegate: currentVC, id: user_Id)
            } else if category == "open_group" {
                let comment_Id = jsonObject.getString(key: "comment_Id")
                openGroup(delegate: currentVC, id: comment_Id)
            } else if category == "open_notification" {
                openNotification(delegate: currentVC)
            }
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let currentVC = getCurrentVC() else {
            return (ApplicationDelegate.shared.application(app, open: url, options: options))
        }
        if url.absoluteString.contains("openWingMeLocation://id=".lowercased()) {
            if let id = url.absoluteString.split(separator: "=").last {
                openLocation(delegate: currentVC, id: "\(id)")
            }
        } else if url.absoluteString.contains("openWingMeBusinessCard://id=".lowercased()) {
            if let id = url.absoluteString.split(separator: "=").last {
                openBusinessCard(delegate: currentVC, id: "\(id)")
            }
        }
        return (ApplicationDelegate.shared.application(app, open: url, options: options))
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Wing_Me")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func saveImages() {
        let encoder = PropertyListEncoder()
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let productURL = directory.appendingPathComponent("SavedImages").appendingPathExtension("plist")
        let encodedProduct = try? encoder.encode(Constants.savedImages)
        try? encodedProduct?.write(to: productURL, options: .noFileProtection)
    }
    
    func openChat(delegate: UIViewController, id: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "ChatVC") as? ChatVC {
            viewController.id = id
            viewController.close = {
                delegate.dismiss(animated: true)
            }
            viewController.modalPresentationStyle = .currentContext
            delegate.present(viewController, animated: true, completion: nil)
        }
    }
    
    func openGroup(delegate: UIViewController, id: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "GroupChatVC") as? GroupChatVC {
            viewController.id = id
            viewController.close = {
                delegate.dismiss(animated: true)
            }
            viewController.modalPresentationStyle = .currentContext
            delegate.present(viewController, animated: true, completion: nil)
        }
    }
    
    func openNotification(delegate: UIViewController) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "NotificationVC") as? NotificationVC {
            viewController.modalPresentationStyle = .currentContext
            delegate.present(viewController, animated: true, completion: nil)
        }
    }
    
    func openLocation(delegate: UIViewController, id: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "SingleLocationVC") as? SingleLocationVC {
            viewController.id = id
            delegate.present(viewController, animated: true, completion: nil)
        }
    }
    
    func openBusinessCard(delegate: UIViewController, id: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "UserLinksVC") as? UserLinksVC {
            viewController.id = id
            delegate.present(viewController, animated: true, completion: nil)
        }
    }
    
    func getToken() {
        Messaging.messaging().subscribe(toTopic: "Main")
        
        if let tmobile = Messaging.messaging().fcmToken {
            print("\n\ntoken\n\(tmobile)\n\n")
            firebaseToken = tmobile
            
            guard let _ = UserDefaults.standard.object(forKey: "Token") else {
                return
            }
            guard let _ = UserDefaults.standard.object(forKey: "Sent") else {
                request()
                return
            }
        }
    }
    
    func request() {
        let url = URL(string: Constants.url + "update_token.php")!
        let postString = "language=\(Strings.language)" + "&firebase=\(firebaseToken)" + "&uid=\(Constants.getUID())"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postString.data(using: .utf8)
        
        if let token = UserDefaults.standard.object(forKey: "Token") as? String {
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            
            guard let data = data, error == nil else {
                let delay = DispatchTime.now() + 2
                DispatchQueue.main.asyncAfter(deadline: delay, execute: {
                    self.connectionError()
                })
                return
            }
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as AnyObject {
                DispatchQueue.main.async {
                    print(jsonObject)
                    self.requestSuccess(jsonObject: jsonObject)
                }
            } else {
                let responseString = String(data: data, encoding: .utf8)
                print(responseString as AnyObject)
            }
        }
        task.resume()
    }
    
    func connectionError() {
        request()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
        if let error = jsonObject["error"] as? String {
            if error == "0" {
                UserDefaults.standard.set(true, forKey: "Sent")
            }
        }
    }
    
    func getCurrentVC() -> UIViewController? {
        if var currentVC = UIApplication.shared.currentKeyWindow?.rootViewController {
            while let presentedViewController = currentVC.presentedViewController {
                currentVC = presentedViewController
            }
            return currentVC
        }
        return nil
    }
}

let appDelegate = UIApplication.shared.delegate as! AppDelegate
let context = appDelegate.persistentContainer.viewContext
