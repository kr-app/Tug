// AddMoreMenu.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class AddMoreMenu: NSObject, NSMenuDelegate {
	static let shared = AddMoreMenu()

	var menu: NSMenu!

	override init() {
		super.init()
		menu = NSMenu(withTitle: "menu", delegate: self, autoenablesItems: false)
	}
	
	func menuNeedsUpdate(_ menu: NSMenu) {

		menu.removeAllItems()

		// http://feeds.feedburner.com/arstechnica/tech-policy
		
		// From Pasteboard
		var url: URL? = nil
		if let string = NSPasteboard.general.string(forType: .string) {
			if string.count > 5 && string.count < 1024 && string.contains(".") == true && string.contains("/") == true {
				url = URL(string: string)
			}
		}
	
		if let url = url {
			menu.addItem(NSMenuItem(withTitle: THLocalizedString("Add \"\(url.th_reducedHost)\""), target: self, action: #selector(mi_menuAction), representedObject: url, tag: 13,  enabled: true))
			menu.addItem(NSMenuItem(withTitle: url.absoluteString, enabled: false))
		}
		else {
			menu.addItem(NSMenuItem(withTitle: THLocalizedString("No URL in pasteboard"), enabled: false))
		}
		menu.addItem(NSMenuItem.separator())
		
		// RSS of front site
		let rssFromBrowser = RssScriptingTools.shared.rssFeedOfFrontBrowser()
		let installedRss = rssFromBrowser?.first(where: { RssChannelManager.shared.channel(withUrl: $0.rss) != nil })

		if let rss = installedRss {
			menu.addItem(NSMenuItem(withTitle: THLocalizedString("RSS for \"\(rss.title)\" Installed"), enabled: false))
		}
		else if rssFromBrowser != nil && rssFromBrowser!.count > 0 {
			for rss in rssFromBrowser! {
				menu.addItem(NSMenuItem(withTitle: THLocalizedString("Add \"\(rss.title)\""), target: self, action: #selector(mi_menuAction), representedObject: rss, tag: 12, enabled: true))
				menu.addItem(NSMenuItem(withTitle: rss.rss.absoluteString, enabled: false))
				menu.addItem(NSMenuItem(withTitle: rss.site.th_reducedHost, enabled: false))
				menu.addItem(NSMenuItem.separator())
			}
		}
		else {
			menu.addItem(NSMenuItem(withTitle: THLocalizedString("No RSS from current browser"), enabled: false))
		}

	}

	@objc func mi_menuAction(_ sender: NSMenuItem) {
		if sender.tag == 12 { // add rss
			let rss = sender.representedObject as! RssFromSource
			if RssChannelManager.shared.addChannel(url: rss.rss) == nil {
				THLogError("addChannel == nil rss:\(rss)")
			}
		}
		else if sender.tag == 13 { // add url
			let url = sender.representedObject as! URL
			if RssChannelManager.shared.addChannel(url: url) == nil {
				THLogError("addChannel == nil url:\(url)")
			}
		}
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
