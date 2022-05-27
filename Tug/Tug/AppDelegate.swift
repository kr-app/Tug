//  AppDelegate.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, MenuListControllerDelegateProtocol, THHotKeyCenterProtocol {
	
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
		THLogInfo("config:\(THRunningApp.config() as NSDictionary))")

#if DEBUG
		THRunningApp.killOtherApps()
#endif

		THHelperRunningApp.shared.configure(withAppIdentifier: "com.kr-app.TugViewer")

		barIcon.barItem.button!.target = self
		barIcon.barItem.button!.action = #selector(barItemAction)
		barIcon.barItem.button!.sendAction(on: [.leftMouseUp, .rightMouseUp]) // This is important
		let menu = NSMenu()
		menu.addItem(NSMenuItem(title: "nil", action: nil, keyEquivalent: ""))
		barIcon.barItem.button!.menu = menu

		RssChannelFilterManager.shared.printToConsole()
		//RssChannelFilterManager.shared.synchronizeToDisk()

		RssChannelManager.shared.refresh()
		YtChannelManager.shared.refresh()

		barIcon.updateBadge()

		THHotKeyCenter.shared().register(THHotKeyRepresentation.init(fromUserDefaultsWithTag: 1))

		updator = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { (Timer) in
			RssChannelManager.shared.refresh()
			YtChannelManager.shared.refresh()
		})

		NotificationCenter.default.addObserver(self, selector: #selector(n_channelUpdated), name: ChannelManager.channelUpdatedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(n_channelItemUpdated), name: ChannelManager.channelItemUpdatedNotification, object: nil)
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		PPPaneRequester.shared.requestHide(withAnimation: false)
//		RssChannelManager.shared.synchronise()
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

	@objc private func timerAppActivatedAction(_ sender: Timer) {
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
	
	@objc private func barItemAction() {
		if paneWindowIsVisible() == true {
			hidePaneWindow(animated: true, restore: true)
		}
		else {
			THFrontmostAppSaver.shared.save()
			showPaneWindow(animated: true)
		}
	}

	@objc func hotKeyCenter(_ sender: THHotKeyCenter, pressedHotKey hotKey: [AnyHashable : Any]?) {
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
		if let menuListController = self.menuListController {
			if menuListController.isHidding == false || menuListController.isShowing == true {
				return true
			}
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

		self.barIcon.setIsPressed(true)

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
		menuListController?.showWindow(in: zone, onScreen: screen)
	
		if UserPreferences.shared.actionOnItemClick == nil {
			if THHelperRunningApp.shared.openApp(wait: false) == false {
				THLogError("openApp == false")
			}
		}
	}
	
	private func hidePaneWindow(animated: Bool, restore: Bool) {
		guard let menu = menuListController, menu.canHidePaneWindow()
		else {
			return
		}

		menu.hideWindow(completion: { () in
			if menu != self.menuListController {
				return
			}

			self.menuListController = nil
			self.barIcon.setIsPressed(false)

			if restore == true {
				THFrontmostAppSaver.shared.restore()
			}
		})
	}
	
	// MARK: -

	@objc private func n_channelUpdated(_ notification: Notification) {
		barIcon.updateBadge()
	}

	@objc private func n_channelItemUpdated(_ notification: Notification) {
		barIcon.updateBadge()
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
