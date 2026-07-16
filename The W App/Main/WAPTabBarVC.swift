import UIKit

// 3-tab replacement for the old 5-tab alpha-crossfade MainVC.
// Tabs: Location (pin) | Feed/W (center) | Messages (envelope)
final class WAPTabBarVC: UITabBarController {

    private var feedVC: NewMyLocationVC?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupTabs()
        appDelegate.inLocation = false
        appDelegate.getToken()
    }

    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Colors.black
        appearance.stackedLayoutAppearance.normal.iconColor = .white
        appearance.stackedLayoutAppearance.selected.iconColor = Colors.blue
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        tabBar.tintColor = Colors.blue
    }

    private func setupTabs() {
        let sb = UIStoryboard(name: "Main", bundle: nil)

        // Tab 1 — Locations (pin icon)
        let locationsVC = sb.instantiateViewController(withIdentifier: "LocationsVC") as! LocationsVC
        let locationsNav = UINavigationController(rootViewController: locationsVC)
        locationsNav.setNavigationBarHidden(true, animated: false)
        locationsNav.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(systemName: "mappin.and.ellipse"),
            tag: 1
        )

        // Tab 2 — Feed / W logo (center)
        let feed = sb.instantiateViewController(withIdentifier: "NewMyLocationVC") as! NewMyLocationVC
        feedVC = feed
        let feedNav = UINavigationController(rootViewController: feed)
        feedNav.setNavigationBarHidden(true, animated: false)
        feedNav.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "icon_watermark")?.withRenderingMode(.alwaysTemplate),
            tag: 2
        )

        // Tab 3 — Messages (envelope icon)
        let messagesVC = sb.instantiateViewController(withIdentifier: "MessagesVC") as! MessagesVC
        let messagesNav = UINavigationController(rootViewController: messagesVC)
        messagesNav.setNavigationBarHidden(true, animated: false)
        messagesNav.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(systemName: "envelope"),
            tag: 3
        )

        // Wire cross-VC delegates: LocationsVC needs to call wingIn on the
        // feed when user taps a venue. Use headless MainVC bridge while
        // full Supabase migration of these VCs is in progress.
        let bridge = makeBridge(locationsVC: locationsVC)
        locationsVC.delegate = bridge
        messagesVC.delegate = bridge
        feed.delegate = bridge

        viewControllers = [locationsNav, feedNav, messagesNav]
        selectedIndex = 1
    }

    private func makeBridge(locationsVC: LocationsVC) -> MainVC {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let bridge = sb.instantiateViewController(withIdentifier: "MainVC") as! MainVC
        bridge.wingIn = { [weak self] customCell in
            self?.feedVC?.wingIn(customCell: customCell)
            self?.selectedIndex = 1
        }
        bridge.hideLocation = { [weak self] in
            self?.feedVC?.hideLocation()
        }
        bridge.checkLocation = locationsVC.checkLocation
        return bridge
    }
}
