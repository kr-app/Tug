// PreferencesWindowController.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class PreferencesWindowController : NSWindowController,
																NSWindowDelegate,
																THHotKeyFieldViewChangeObserverProtocol {

	static let shared = PreferencesWindowController(windowNibName: "PreferencesWindowController")

	@IBOutlet var checkForUpdateButton: NSButton!
	@IBOutlet var relaunchOnLoginButton: NSButton!
	@IBOutlet var hotKeyButton: NSButton!
	@IBOutlet var hotKeyField: THHotKeyFieldView!

	@IBOutlet var refreshInterval: NSPopUpButton!
	@IBOutlet var actionOnClick: NSPopUpButton!
	@IBOutlet var previewPopMenu: NSPopUpButton!

	override func windowDidLoad() {
		super.windowDidLoad()
	
		self.window!.title = THLocalizedString("Tug Preferences")

		let hotKey = THHotKeyRepresentation.fromUserDefaults()
		hotKeyButton.state = (hotKey != nil && hotKey!.isEnabled == true) ? .on : .off
		hotKeyField.setControlSize(hotKeyButton.controlSize)
		hotKeyField.setChangeObserver(self,
																keyCode: hotKey?.keyCode ?? 0,
																modifierFlags: hotKey?.modifierFlags ?? 0,
																isEnabled: hotKey?.isEnabled ?? false)
		
		refreshInterval.removeAllItems()
		refreshInterval.menu!.addItem(NSMenuItem(withTitle: THLocalizedString("Default (5 min)"), tag: 0, enabled: true))
		refreshInterval.menu!.addItem(NSMenuItem.separator())
		refreshInterval.menu!.addItem(NSMenuItem(withTitle: THLocalizedString("15 minutes"), tag: 15, enabled: true))
		refreshInterval.menu!.addItem(NSMenuItem(withTitle: THLocalizedString("30 minutes"), tag: 30, enabled: true))
		refreshInterval.menu!.addItem(NSMenuItem(withTitle: THLocalizedString("1 hour"), tag: 60, enabled: true))
		refreshInterval.selectItem(withTag: UserPreferences.shared.refreshInterval ?? 0)
		
		actionOnClick.removeAllItems()
		actionOnClick.menu!.addItem(NSMenuItem(withTitle: THLocalizedString("None"), representedObject: "none", enabled: true))
		actionOnClick.menu!.addItem(NSMenuItem.separator())
		actionOnClick.menu!.addItem(NSMenuItem(withTitle: THLocalizedString("Show Preview"), representedObject: nil, enabled: true))
		actionOnClick.menu!.addItem(NSMenuItem(withTitle: THLocalizedString("Open in Browser"), representedObject: "openInBrowser", enabled: true))
		actionOnClick.selectItem(withRepresentedObject: UserPreferences.shared.actionOnItemClick)

		previewPopMenu.removeAllItems()
		previewPopMenu.menu!.addItem(NSMenuItem(withTitle: THLocalizedString("Hide"), tag: 0, enabled: true))
		previewPopMenu.menu!.addItem(NSMenuItem(withTitle: THLocalizedString("Keep"), tag: 1, enabled: true))
		previewPopMenu.selectItem(withTag: UserPreferences.shared.previewHighlightMode ?? 0)
	}
	
	// MARK: -

	func windowDidBecomeMain(_ notification: Notification) {
		updateUILoginItem()
	}

	// MARK: -

	private func updateUILoginItem() {
		relaunchOnLoginButton.state = THAppInLoginItem.loginItemStatus()
	}

	// MARK: -
	
	@IBAction func relaunchOnLoginButtonAction(_ sender: NSButton) {
		THAppInLoginItem.setIsLoginItem(sender.state == .on)
		updateUILoginItem()
	}

	@IBAction func hotKeyButtonAction(_ sender: NSButton) {
		self.hotKeyField.setIsEnabled(sender.state == .on)
	}

	// MARK: -

	func hotKeyFieldView(_ sender: THHotKeyFieldView!, didChangeWithKeyCode keyCode: UInt, modifierFlags: UInt, isEnabled: Bool) -> Bool {
		THHotKeyRepresentation(keyCode: keyCode, modifierFlags: modifierFlags, isEnabled: isEnabled).saveToUserDefaults()
		
		if isEnabled == true {
			return THHotKeyCenter.shared().registerHotKey(withKeyCode: keyCode, modifierFlags: modifierFlags, tag: 1)
		}

		return THHotKeyCenter.shared().unregisterHotKey(withTag: 1)
	}

	@IBAction func refreshIntervalPopAction(_ sender: NSPopUpButton) {
		UserPreferences.shared.refreshInterval = sender.selectedItem?.tag
		UserPreferences.shared.synchronize()
	}

	@IBAction func actionOnClickPopAction(_ sender: NSPopUpButton) {
		UserPreferences.shared.actionOnItemClick = sender.selectedItem?.representedObject as? String
		UserPreferences.shared.synchronize()
	}

	@IBAction func previewPopAction(_ sender: NSPopUpButton) {
		UserPreferences.shared.previewHighlightMode = sender.selectedItem?.tag
		UserPreferences.shared.synchronize()
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
