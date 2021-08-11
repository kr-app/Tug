// SettingsMenu.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class SettingsMenu: NSObject, NSMenuDelegate {
	
	static let shared = SettingsMenu()

	var menu: NSMenu!
	
	override init() {
		super.init()
		menu = NSMenu(title: "menu", delegate: self, autoenablesItems: false)
	}
	
	func menuNeedsUpdate(_ menu: NSMenu) {

		menu.removeAllItems()

		menu.addItem(THMenuItem(title: THLocalizedString("About Tug…"), block: { () in
			NSApplication.shared.activate(ignoringOtherApps: true)
			NSApplication.shared.orderFrontStandardAboutPanel(nil)
		}))

		menu.addItem(NSMenuItem.separator())
		menu.addItem(THMenuItem(title: THLocalizedString("Preferences…"), block: { () in
			PreferencesWindowController.shared.showWindow(nil)
		}))

		menu.addItem(NSMenuItem.separator())
		menu.addItem(THMenuItem(title: THLocalizedString("Channel List…"), block: { () in
			ChannelListWindowController.shared.showWindow(nil)
		}))

		menu.addItem(NSMenuItem.separator())
		menu.addItem(THMenuItem(title: THLocalizedString("Quit"), block: { () in
			NSApplication.shared.terminate(nil)
		}))

	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
