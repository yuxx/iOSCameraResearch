import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = window else {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line) window is nil.", level: .err)
            return false
        }
        if #available(iOS 13.0, *) {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
            window.rootViewController = ViewController()
        } else {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
            window.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        }
        window.makeKeyAndVisible()
        return true
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

