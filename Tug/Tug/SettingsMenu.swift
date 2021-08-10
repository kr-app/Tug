// SettingsMenu.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class SettingsMenu: NSObject, NSMenuDelegate {
	
	static let shared = SettingsMenu()

	var menu: NSMenu!
	
	override init() {
		super.init()
		menu = NSMenu(withTitle: "menu", delegate: self, autoenablesItems: false)
	}
	
	func menuNeedsUpdate(_ menu: NSMenu) {

		menu.removeAllItems()

		menu.addItem(THMenuItem(withTitle: THLocalizedString("About Tug…"), block: { () in
			NSApplication.shared.activate(ignoringOtherApps: true)
			NSApplication.shared.orderFrontStandardAboutPanel(nil)
		}))

		menu.addItem(NSMenuItem.separator())
		
		menu.addItem(THMenuItem(withTitle: THLocalizedString("Preferences…"), block: { () in
			PreferencesWindowController.shared.showWindow(nil)
		}))

		menu.addItem(NSMenuItem.separator())

		menu.addItem(THMenuItem(withTitle: THLocalizedString("Channel List…"), block: { () in
			ChannelListWindowController.shared.showWindow(nil)
		}))

		menu.addItem(NSMenuItem.separator())

		menu.addItem(THMenuItem(withTitle: THLocalizedString("HELP_GOTO_WEBSITE"), block: { () in
			
		}))
		menu.addItem(THMenuItem(withTitle: THLocalizedString("HELP_EMAIL_SUPPORT"), block: { () in
			
		}))

		menu.addItem(NSMenuItem.separator())

		menu.addItem(THMenuItem(withTitle: THLocalizedString("Quit"), block: { () in
			NSApplication.shared.terminate(nil)
		}))

	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
