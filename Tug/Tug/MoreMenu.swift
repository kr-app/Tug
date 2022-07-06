// MoreMenu.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class MoreMenu: NSObject, NSMenuDelegate {
	
	static let shared = MoreMenu()

	lazy var menu = NSMenu(title: "menu", delegate: self, autoenablesItems: false)

	func menuNeedsUpdate(_ menu: NSMenu) {

		menu.removeAllItems()

		if menu.title == "micd-menu" {
			loadMicdMenu(menu)
			return
		}
		else if menu.title == "rss-menu" {
			loadRssMenu(menu)
			return
		}
		else if menu.title == "yt-menu" {
			loadYtMenu(menu)
			return
		}

		menu.addItem(THMenuItem(title: THLocalizedString("About Tug…"), block: { () in
			NSApplication.shared.activate(ignoringOtherApps: true)
			NSApplication.shared.orderFrontStandardAboutPanel(nil)
		}))

		menu.addItem(NSMenuItem.separator())
		menu.addItem(THMenuItem(title: THLocalizedString("Preferences…"), block: { () in
			NSApplication.shared.activate(ignoringOtherApps: true)
			PreferencesWindowController.shared.showWindow(nil)
		}))
		menu.addItem(THMenuItem(title: THLocalizedString("Channel List…"), block: { () in
			ChannelListWindowController.shared.showWindow(nil)
		}))

		menu.addItem(NSMenuItem.separator())
		menu.addItem(THMenuItem(title: THLocalizedString("Reload All"), block: { () in
			RssChannelManager.shared.reloadAll()
			YtChannelManager.shared.reloadAll()
		}))

		menu.addItem(NSMenuItem.separator())
		menu.addItem(NSMenuItem(title: THLocalizedString("Send to Micd"), submenu: NSMenu(title: "micd-menu", delegate: self, autoenablesItems: false)))
		menu.addItem(NSMenuItem(title: THLocalizedString("RSS Feed"), submenu: NSMenu(title: "rss-menu", delegate: self, autoenablesItems: false)))
		menu.addItem(NSMenuItem(title: THLocalizedString("Yt Channel"), submenu: NSMenu(title: "yt-menu", delegate: self, autoenablesItems: false)))

		menu.addItem(NSMenuItem.separator())
		menu.addItem(THMenuItem(title: THLocalizedString("Quit"), block: { () in
			NSApplication.shared.terminate(nil)
		}))
	}

	// MARK: -

	private func loadMicdMenu(_ menu: NSMenu) {
		if let url = ExtractClipboardUrl() {
			menu.addItem(THMenuItem(title: THLocalizedString("Send \"\(url.th_presentableUrl())\" to micd"), block: { () in
				SendToMicd(url)
			}))
		}
		else {
			menu.addItem(NSMenuItem(title: THLocalizedString("No URL in pasteboard"), enabled: false))
		}
	}

	private func loadRssMenu(_ menu: NSMenu) {
		if let url = ExtractClipboardUrl() {
			menu.addItem(THMenuItem(title: THLocalizedString("Add \"\(url.th_reducedHost)\""), block: { () in
				if RssChannelManager.shared.addChannel(url: url) == nil {
					THLogError("addChannel == nil url:\(url)")
					return
				}
				NSAlert(withTitle: "RssChannel \"\(url.th_reducedHost)\" added", message: url.absoluteString).runModal()
			}))
			menu.addItem(NSMenuItem(title: url.absoluteString, enabled: false))
		}
		else {
			menu.addItem(NSMenuItem(title: THLocalizedString("No URL in pasteboard"), enabled: false))
		}
		menu.addItem(NSMenuItem.separator())

		// RSS - from browser
		let feeds = THWebBrowserScriptingTools.rssFeedsOfFrontTab()

		if let feed = feeds?.first(where: { RssChannelManager.shared.channel(withUrl: $0.rss) != nil }) {
			menu.addItem(NSMenuItem(title: THLocalizedString("Feed for \"\(feed.title)\" Installed"), enabled: false))
		}
		else if let feeds = feeds {
			for feed in feeds {
				menu.addItem(THMenuItem(title: THLocalizedString("Add \"\(feed.title)\""), block: { () in
					if RssChannelManager.shared.addChannel(url: feed.rss) == nil {
						THLogError("addChannel == nil feed:\(feed)")
						return
					}
					NSAlert(withTitle: "RssChannel \"\(feed.title)\" added", message: feed.rss.absoluteString).runModal()
				}))

				menu.addItem(NSMenuItem(title: feed.rss.absoluteString, enabled: false))
				menu.addItem(NSMenuItem(title: feed.site.th_reducedHost, enabled: false))
				menu.addItem(NSMenuItem.separator())
			}
		}
		else {
			menu.addItem(NSMenuItem(title: THLocalizedString("No Rss feed found"), enabled: false))
		}
	}

	private func loadYtMenu(_ menu: NSMenu) {
		let frontTab = THWebBrowserScriptingTools.getFrontTab()

		if let frontTab = frontTab, frontTab.empty == false {
			menu.addItem(THMenuItem(title: THLocalizedString("Add \"\(frontTab.title)\""), block: { () in
				guard let url = frontTab.url, let source = THWebBrowserScriptingTools.sourceOfFrontTab(targetUrl: url)
				else {
					THLogError("source == nil frontTab:\(frontTab)")
					return
				}

				guard let videoId = YtChannelVideoIdExtractor.extractVideoId(fromSource: source)
				else {
					THLogError("videoId == nil frontTab:\(frontTab)")
					return
				}

				guard let channel = YtChannelManager.shared.addChannel(videoId: videoId)
				else {
					THLogError("addChannel == false:\(frontTab)")
					return
				}

				if let poster = YtChannelVideoIdExtractor.extractThumbnail(fromSource: source) {
					channel.poster = poster
				}

				NSAlert(withTitle: "YtChannel \"\(frontTab.title)\" added", message: frontTab.url).runModal()
			}))
		}
		else {
			menu.addItem(NSMenuItem(title: THLocalizedString("No front tab"), enabled: false))
		}
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
