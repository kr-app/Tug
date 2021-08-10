//  ChannelManager.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class ChannelManager {
	static let shared = ChannelManager()
	static let channelUpdatedNotification = Notification.Name("ChannelManager-channelUpdatedNotification")
	static let dirPath = URL(fileURLWithPath: THFunctions.appSupportPath("channels"))

	var lastUpdate: CFTimeInterval = 0.0 { didSet {
							UserDefaults.standard.set(lastUpdate, forKey: "ChannelManager-lastUpdate")
						} }
	var onError = false
	var p_openInBrowser: String?
	var openInBrowsers: [[String: Any]]!
	var openInBrowser: String? { didSet {
						UserDefaults.standard.set(openInBrowser, forKey: "ChannelManager-openInBrowser")
					} }

	private var p_selectedBookmarks: [String]!
	private var p_channels: [Channel] = []
	private var mLastFeedByChanel = [String: String]()

	init() {
		lastUpdate = CFTimeInterval(UserDefaults.standard.double(forKey: "ChannelManager-lastUpdate"))

		p_selectedBookmarks = UserDefaults.standard.stringArray(forKey: "ChannelManager-selectedBookmarks")
		if p_selectedBookmarks == nil {
			p_selectedBookmarks = []
		}

		do {
			let files = try FileManager.default.contentsOfDirectory(	at: Self.dirPath,
																									includingPropertiesForKeys:nil,
																									options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
			for file in files {
				if let c = Channel.channel(fromFile: file) {
					p_channels.append(c)
				}
				else {
					THLogError("c == nil file:\(file)")
				}
			}
		}
		catch {
			THLogError("contentsOfDirectory error:\(error)")
		}

		openInBrowsers = []
		for br in [		["name": "safari", "path": "/Applications/Safari.app"],
							["name": "firefox", "path": "/Applications/Firefox.app"]] {
			let p = br["path"]! as String
			if FileManager.default.fileExists(atPath: p) == true {
				openInBrowsers.append(["name": br["name"]!, "url": URL(fileURLWithPath: p)])
			}
		}

		openInBrowser = UserDefaults.standard.string(forKey: "ChannelManager-openInBrowser")
		if openInBrowser == nil {
			openInBrowser = openInBrowsers.first!["name"] as? String
		}

	}

	func openInBrowser(url: URL, completion: @escaping (Bool) -> Void) {
	
		var browser = openInBrowsers.filter( { ($0["name"] as! String) == openInBrowser }).first?["url"] as? URL
		if browser == nil {
			browser = openInBrowsers.first!["url"] as? URL
		}

		let config = NSWorkspace.OpenConfiguration()

		NSWorkspace.shared.open([url], withApplicationAt: browser!, configuration: config, completionHandler: {(app: NSRunningApplication?, error: Error?) in
			completion((app != nil || error == nil) ? true : false)
		})
		
	}

	func hasSelectedBookmarks(_ selectedBookmarks: String) -> Bool {
		return p_selectedBookmarks.contains(selectedBookmarks)
	}

	func addSelectedBookmarks(_ selectedBookmarks: String) {
		if p_selectedBookmarks.contains(selectedBookmarks) == false {
			p_selectedBookmarks.append(selectedBookmarks)
			UserDefaults.standard.set(p_selectedBookmarks, forKey: "ChannelManager-selectedBookmarks")
			UserDefaults.standard.synchronize()
		}
	}

	func removeSelectedBookmarks(_ selectedBookmarks: String) {
		p_selectedBookmarks?.removeAll(where: { $0 == selectedBookmarks })
		UserDefaults.standard.set(p_selectedBookmarks, forKey: "ChannelManager-selectedBookmarks")
		UserDefaults.standard.synchronize()
	}

	func refreshChannels() {
		let bar = THSafariList.shared()?.bookmarks(nil)?.first as? THSafariFolder

		if lastUpdate == 0.0 {
			
//			for c in p_channels {
//				if bar?.bookmark(withId: c.bookmarkId) == nil {
//					THLogError("obsolte c:\(c)")
//				}
//			}

		}

		lastUpdate = CFAbsoluteTimeGetCurrent()
		onError = bar != nil ? false : true
		
		if let bar = bar {
			startUpdateOfChannels(fromBookmarks: bar, included: false)
		}
	}

	func channel(forBookmark bookmarkId: String) -> Channel? {
		return p_channels.first(where: { $0.bookmarkId == bookmarkId })
	}

	func nbUnreaded(bookmarkFolder: THSafariFolder?) -> Int {

		var r = 0

		if let bookmarkFolder = bookmarkFolder {
			for b in bookmarkFolder.childs {
				if let bs = b as? THSafariSite {
					if let c = channel(forBookmark: bs.identifier) {
						r += c.nbUnreaded()
					}
				}
				else if let bf = b as? THSafariFolder {
					r += nbUnreaded(bookmarkFolder: bf)
				}
			}
		}
		else {
			for c in p_channels {
				r += c.nbUnreaded()
			}
		}

		return r
	}

	func unreadedChannels(recentRef: TimeInterval?) -> [Channel] {
		let r = p_channels.filter( { ($0.nbUnreaded() > 0 || (recentRef != nil && $0.hasRecent(refDate: recentRef!))) })
		return r.sorted(by: {
			if let p0 = $0.feeds.first?.published, let p1 = $1.feeds.first?.published {
				return p0 > p1
			}
			return false
		})
	}

	func markAllAsReaded() {
		for c in p_channels {
			var changed = false
			for f in c.feeds {
				if f.checked == false {
					f.checked = true
					changed = true
				}
			}
			if changed == true {
				if c.save(toDir: Self.dirPath) == false {
					THLogError("save == false")
				}
			}
		}
	}

	func markAsReaded(channelBId: String, feed: String?) {
		if let c = self.channel(forBookmark: channelBId) {
			for f in c.feeds {
				if (feed == nil || (feed != nil && feed! == f.identifier)) {
					f.checked = true
				}
			}
			if c.save(toDir: Self.dirPath) == false {
				THLogError("save == false")
			}
		}
	}

	func hasUnnotifiedFeed(channel: Channel) -> ChannelFeed? {

		if let last = channel.feeds.first {
			let cId = channel.bookmarkId!
			if mLastFeedByChanel[cId] == nil {
				mLastFeedByChanel[cId] = last.identifier
				return nil
			}
			if mLastFeedByChanel[cId] != last.identifier {
				mLastFeedByChanel[cId] = last.identifier
				return last
			}
		}
		
		return nil
	}

	private func ytChannelId(fromUrl url: URL) -> String? {
		if let s = try? String(contentsOf: url, encoding: .utf8) {
			let ss = s as NSString
			let rS = ss.range(of: "<meta itemprop=\"channelId\" content=\"", options: .caseInsensitive)
			if rS.location != NSNotFound {
				let rsEnd = rS.location + rS.length
				let rE = ss.range(of: "\"", options: .caseInsensitive, range: NSMakeRange(rsEnd, ss.length - rsEnd), locale: nil)
				if rE.location != NSNotFound {
					return ss.substring(with: NSMakeRange(rsEnd, rE.location - rsEnd))
				}
			}
		}
		return nil
	}

	private func startUpdateOfChannels(fromBookmarks bookmarks: THSafariFolder, included: Bool) {

		let pOn = included == true ? true : p_selectedBookmarks.contains(bookmarks.identifier)

		for b in bookmarks.childs {

			if let bs = b as? THSafariSite {
				var c = channel(forBookmark: bs.identifier)

				if pOn == true || p_selectedBookmarks.contains(bs.identifier) == true {
					if c == nil {
						let pc = bs.url()!.pathComponents
						var vId: String?
						if let vIdx = pc.firstIndex(of: "channel") {
							vId = pc[vIdx + 1]
						}
				
						if vId == nil {
							THLogWarning("vId == nil bs: \(bs) pc:\(pc)")
							vId = ytChannelId(fromUrl: bs.url())
							if vId == nil {
								THLogError("vId == nil bs: \(bs) pc:\(pc)")
							}
						}
						
						c = Channel(bookmarkId: bs.identifier, ytId: vId)
						p_channels.append(c!)
						if c!.save(toDir: Self.dirPath) == false {
							THLogError("save == false")
						}
					}
					
					c!.update(completion: {(ok: Bool, error: String?) in
						if ok == false {
							THLogError("ok == false error:\(error ?? "nil")")
						}
						else {
							if c!.save(toDir: Self.dirPath) == false {
								THLogError("save == false c:\(c!)")
							}
						}
						NotificationCenter.default.post(name: ChannelManager.channelUpdatedNotification, object: self, userInfo: ["channel": c!])
					})
				}
				else {
					if let c = c {
						c.cancel()
						p_channels.removeAll(where: { $0.bookmarkId == bs.identifier})
					}
				}
			}
			else if let bf = b as? THSafariFolder {
				startUpdateOfChannels(fromBookmarks: bf, included: pOn)
			}
		}
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
