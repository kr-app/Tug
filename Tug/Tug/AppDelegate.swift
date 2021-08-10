//  AppDelegate.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate,
													MenuListControllerDelegateProtocol,
													THHotKeyCenterProtocol {
	
	@IBOutlet weak var channelsWin: NSWindow?

	private var menuListController: MenuListController?
	private var barIcon = StatusIcon()
	private var updator: Timer!
	private var lastUpdate: CFTimeInterval = 0.0
	private var lastFeedByChanel = [String: String]()
	private var lastPresentedUnNotification: Date?

	private var timerAppActivated: Timer?
//	private var timerMenubar: Timer?

	// MARK:-

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		THLogInfo("config:\(THRunningApp.config())")

#if DEBUG
		THRunningApp.killOtherApps()
#endif

/*		for rss in [		["macg.com", "https://www.macg.co/news/feed"],
							["lefigaro.fr", "https://www.lefigaro.fr/rss/figaro_actualites.xml"],
							[nil, "https://www.lemonde.fr/rss/une.xml"],
							["lepoint.fr", "https://www.lepoint.fr/rss.xml"],
							["macbidouille.com", "https://macbidouille.com/rss"],
							["ladepeche.fr", "https://www.ladepeche.fr/rss.xml"],
							["latribune.fr", "https://www.latribune.fr/feed.xml"],
							["grimper.com", "https://www.grimper.com/feed/all"],
							["valeursactuelles.com", "https://www.valeursactuelles.com/feed?post_type=post"],
							["letemps.ch", "https://www.letemps.ch/feed"],
							["macrumors.com", "http://feeds.macrumors.com/MacRumors-All"],
							["aljazeera.com", "https://www.aljazeera.com/xml/rss/all.xml"],
							["20minutes.fr", "https://www.20minutes.fr/rss/une.xml"],
							[nil, "https://www.ledauphine.com/rss"]
					] {
			RssChannelManager.shared.addChannel(withSite: rss[0] , url: URL(string: rss[1]!)!)
		}*/

		THIconDownloader.shared.setDiskRetention(3.0.th_day)
		THIconDownloader.shared.validity = 0.0
		THIconDownloader.shared.maxSize = 74.0
		THIconDownloader.shared.cropIcon = true
		THIconDownloader.shared.excludedHosts = ["static.latribune.fr"]

		THWebIconLoader.shared.validity = 0.0
		THWebIconLoader.shared.excludedHosts = THIconDownloader.shared.excludedHosts

		THHelperRunningApp.shared.configure(withAppIdentifier: "com.parrotsoft.TugViewer")

//		THCheckForUpdates.shared.configure(appBuild: nil, infoURL: nil)
//		THCheckForUpdates.shared.synchronizeAtLaunch()

		barIcon.barItem.button!.target = self
		barIcon.barItem.button!.action = #selector(barItemAction)
		barIcon.barItem.button!.sendAction(on: [.leftMouseUp, .rightMouseUp]) // This is important
		let menu = NSMenu()
		menu.addItem(NSMenuItem(title: "nil", action: nil, keyEquivalent: ""))
		barIcon.barItem.button!.menu = menu
	
		if THNetworkStatus.hasNetwork() == true {
			RssChannelManager.shared.refresh()
		}

		barIcon.updateBadge()

		updator = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { (Timer) in
			if THNetworkStatus.hasNetwork() == false {
				THLogWarning("no network")
				return
			}

			RssChannelManager.shared.refresh()
		})
		
		NotificationCenter.default.addObserver(self, selector: #selector(n_rssChannelUpdated), name: RssChannelManager.channelUpdatedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(n_rssChannelItemUpdated), name: RssChannelManager.channelItemUpdatedNotification, object: nil)
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		RssChannelManager.shared.synchronise()
	}

	func applicationWillBecomeActive(_ notification: Notification) {
		timerAppActivated?.invalidate()
		timerAppActivated = nil
	}

	func applicationDidResignActive(_ notification: Notification) {
		if paneWindowIsVisible() == true {
			if let frontapp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier {
				if frontapp == THHelperRunningApp.shared.appIdentifier {
					timerAppActivated?.invalidate()
					timerAppActivated = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(timerAppActivatedAction), userInfo: nil, repeats: true)
					return
				}
			}
			hidePaneWindow(animated: true, restore: false)
		}
		THHelperRunningApp.shared.terminateApp()
	}
	
	func applicationWillResignActive(_ notification: Notification) {
	}

	// MARK: -

	@objc func timerAppActivatedAction(_ sender: Timer) {
		let frontapp = NSWorkspace.shared.frontmostApplication
		
		if let appId = frontapp?.bundleIdentifier {
			if appId == THHelperRunningApp.shared.appIdentifier {
				return
			}
		}
		
		if frontapp != nil && frontapp!.processIdentifier == THRunningApp.processId {
			return
		}

		THLogInfo("frontapp is not app or this helper frontapp:\(frontapp)")

		timerAppActivated?.invalidate()
		timerAppActivated = nil
	
		hidePaneWindow(animated: true, restore: false)
		THHelperRunningApp.shared.terminateApp()
	}

	// MARK: -
	
	@objc func barItemAction() {
		if paneWindowIsVisible() == true {
			hidePaneWindow(animated: true, restore: true)
		}
		else {
			THFrontmostAppSaver.shared.save()
			showPaneWindow(animated: true)
		}
	}

	func hotKeyCenter(_ sender: THHotKeyCenter, pressedHotKey hotKey: [AnyHashable : Any]?) {
		barItemAction()
	}

	// MARK: -

	func paneViewControllerDidResignKeyWindow(_ menuListController: MenuListController) {
		if menuListController.canHidePaneWindow() == true {
			if THHelperRunningApp.shared.isActiveApp() == true {
				return
			}
			hidePaneWindow(animated: true, restore: false)
		}
	}

	func paneViewControllerDidPresentExternalItem(_ menuListController: MenuListController) {
		hidePaneWindow(animated: true, restore: false)
	}
	
	// MARK: -

	private func paneWindowIsVisible() -> Bool {
		if menuListController != nil && menuListController!.isHidding == false {
			return true
		}
		return false
	}

	private func showPaneWindow(animated: Bool) {

		NSApplication.shared.activate(ignoringOtherApps: true)

		guard 	let siWindow = barIcon.statusItemWindow,
					let screen = (siWindow.screen ?? NSScreen.main)
		else {
			return
		}
		
//		if timerMenubar == nil {
//			timerMenubar = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(timerMenubarAction), userInfo: nil, repeats: true)
//		}

		let swFrame = siWindow.frame
		var wRect = NSRect(	swFrame.origin.x - screen.frame.origin.x,
											swFrame.origin.y - screen.frame.origin.y,
											swFrame.size.width,
											swFrame.size.height)

		let mbHeight = NSApplication.shared.mainMenu!.menuBarHeight
		wRect.origin.y = screen.frame.size.height - (mbHeight > 0.0 ? mbHeight : 22.0)

//		BOOL isDarkStyle=[THOSAppearance isDarkMode];
//		if (isDarkStyle==NO)
//			swFrame.origin.y-=1.0;

		let zone = NSRect(	swFrame.origin.x.rounded(.down),
										swFrame.origin.y.rounded(.down),
										swFrame.size.width.rounded(.down),
										0.0)

		menuListController = MenuListController(delegate: self)
		menuListController?.showWindow(inZone: zone, onScreen: screen, completion: {() in
		})
	
		if UserPreferences.shared.actionOnItemClick == nil {
			if THHelperRunningApp.shared.openApp(wait: false) == false {
				THLogError("openApp == false")
			}
		}

	}
	
	private func hidePaneWindow(animated: Bool, restore: Bool) {
		if menuListController == nil || menuListController!.canHidePaneWindow() == false {
			return
		}

		menuListController!.hideWindow(completion: { () in

			self.menuListController = nil
			self.barIcon.setIsPressed(false)

			if restore == true {
				THFrontmostAppSaver.shared.restore()
			}
		})
	}
	
	// MARK: -

	@objc func n_rssChannelUpdated(_ notification: Notification) {

		let channel = notification.userInfo!["channel"] as! RssChannel
		//let item = notification.userInfo!["item"] as? RssChannelItem

		for item in channel.items {
			if item.checked == true || THIconDownloader.shared.hasData(forIconUrl: item.thumbnail) == true {
				continue
			}
			THIconDownloader.shared.loadIcon(atURL: item.thumbnail)
		}

		barIcon.updateBadge()
	}

	@objc func n_rssChannelItemUpdated(_ notification: Notification) {

//		let channel = notification.userInfo!["channel"] as! RssChannel
//		let item = notification.userInfo!["item"] as! RssChannelItem

		barIcon.updateBadge()
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
