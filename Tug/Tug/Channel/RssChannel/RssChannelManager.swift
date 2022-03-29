// RssChannelManager.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class RssChannelManager: ChannelManager {

	static let shared = RssChannelManager(dirPath: FileManager.th_documentsPath("RssChannels"))
	
	var filterManager: RssChannelFilterManager?
	private(set) var channels = [RssChannel]()

	// MARK: -
	
	override init(dirPath: String) {
		super.init(dirPath: dirPath)
		loadChannels()
	}

	func loadChannels() {
		let files = try! FileManager.default.contentsOfDirectory(	at: URL(fileURLWithPath: dirPath),
																								includingPropertiesForKeys:nil,
																								options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
		for file in files {
			if file.pathExtension != "plist" {
				continue
			}
			if let channel = RssChannel.channel(fromFile: file.path) {
				channels.append(channel)
			}
			else {
				THLogError("channel == nil file:\(file)")
			}
		}
	
		channels.sort(by: { $0.creationDate < $1.creationDate })
		
		var nbItems = 0
		channels.forEach({ nbItems += $0.items.count })

		var nbUnreaded = 0
		channels.forEach({ nbUnreaded += $0.unreaded() })

		THLogInfo("\(channels.count) channels, nbItems:\(nbItems), nbUnreaded:\(nbUnreaded)")
	}
	
	// MARK: -

	@discardableResult func addChannel(url: URL, startUpdate: Bool = true) -> RssChannel? {
		if channel(withUrl: url) != nil {
			THLogError("another channel found with url:\(url.absoluteString)")
			return nil
		}

		let channel = RssChannel(url: url)
		channels.append(channel)

		if channel.save(toDir: dirPath) == false {
			THLogError("can not save channel:\(channel)")
		}

		if startUpdate == true {
			self.updateChannel(channel.identifier, completion: nil)
		}

		return channel
	}

	func reloadAll() {
		filterManager?.synchronizeFromDisk()

		for channel in channels {
			channel.lastUpdate = nil
		}

		startUpdateOfNextChannel()
	}

	func refresh() {
		filterManager?.synchronizeFromDisk()
		startUpdateOfNextChannel()
	}
	
	// MARK: -
	
	override func recentRefDate() -> TimeInterval {
		Date().timeIntervalSinceReferenceDate - 0.66.th_day
	}

	func channel(withUrl url: URL) -> RssChannel? {
		channels.first(where: { $0.url == url } )
	}
	
	override func channel(withId identifier: String) -> Channel? {
		channels.first(where: { $0.identifier == identifier } )
	}

	override func channelsOnError() -> [Channel]? {
		let r = channels.filter( { $0.lastError != nil } )
		return r.isEmpty ? nil : r
	}

	override func removeChannel(_ channelId: String) {
		super.removeChannel(channelId)
		channels.removeAll(where: {$0.identifier == channelId })
	}

//	func unreadedChannels() -> [RssChannel] {
//		let r = channels.filter( { $0.unreaded() > 0 } )
//		return r.sorted(by: {
//			if let p0 = $0.items.first?.pubDate, let p1 = $1.items.first?.pubDate {
//				return p0 > p1
//			}
//			return false
//		})
//	}

//	func unreadedItems() -> Int {
//		var r = 0
//		for c in channels {
//			r += c.unreaded()
//		}
//		return r
//	}

	func hasWallChannels(withDateRef dateRef: TimeInterval, atLeast: Int) -> Bool {
		var nb = 0
		for channel in channels.filter({ $0.disabled == false }) {
			nb += channel.items.filter( {$0.checkedDate == nil && $0.isRecent(refDate: dateRef) }).count
			if nb >= atLeast {
				return true
			}
		}
		return false
			//return channels.contains(where: { $0.hasUnreaded() && $0.hasRecent(refDate: dateRef) } )
	}

	func unreadedCount() -> Int {
		var r = 0
		for channel in channels.filter( { $0.disabled == false } ) {
			r += channel.unreaded()
		}
		return r
	}

//	func wallChannels(withDateRef dateRef: TimeInterval) -> [RssChannel] {
//		let r = channels.filter( { $0.hasUnreaded() || $0.hasRecent(refDate: dateRef) } )
//		return r.sorted(by: {
//			if let p0 = $0.items.first?.wallDate, let p1 = $1.items.first?.wallDate {
//				return p0 > p1
//			}
//			return false
//		})
//	}

//	func wallChannels() -> [RssChannel] {
//		return channels.sorted(by: {
//			if let p0 = $0.items.first?.wallDate, let p1 = $1.items.first?.wallDate {
//				return p0 > p1
//			}
//			return false
//		})
//	}

	// MARK: -

	@discardableResult private func startUpdateOfNextChannel() -> Bool {
		if channels.contains(where: { $0.isUpdating == true }) == true {
			return false
		}

		let refreshInterval = UserPreferences.shared.refreshInterval
		let refreshTI = (refreshInterval != nil && refreshInterval! > 0) ? TimeInterval(refreshInterval!).th_min : 5.0.th_min
		
		let now = Date().timeIntervalSinceReferenceDate
		let now_time = now - refreshTI
		let now_time_onerror = now - 30.0

		let channels = self.channels.sorted(by: {
					if $0.lastUpdate == nil || $1.lastUpdate == nil {
						return true
					}
					return $0.lastUpdate! < $1.lastUpdate!
				})

		for channel in channels {

			if channel.disabled == true {
				continue
			}
			
			if let lu = channel.lastUpdate {
				if lu.timeIntervalSinceReferenceDate > (channel.lastError != nil ? now_time_onerror : now_time) {
					continue
				}
			}
			
			channel.update(urlSession: urlSession, completion: {(ok: Bool, error: String?) in
				if ok == false {
					THLogError("ok == false error:\(error)")
				}

				if channel.save(toDir: self.dirPath) == false {
					THLogError("can not save channel:\(channel)")
				}

				NotificationCenter.default.post(name: Self.channelUpdatedNotification, object: self, userInfo: ["channel": channel])
				self.startUpdateOfNextChannel()
			})

			return true
		}
	
		return false
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
