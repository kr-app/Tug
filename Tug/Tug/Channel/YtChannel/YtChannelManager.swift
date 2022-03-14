// YtChannelManager.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class YtChannelManager: ChannelManager {

	static let shared = YtChannelManager(dirPath: FileManager.th_documentsPath("YtChannels"))

	private(set) var channels = [YtChannel]()

	// MARK: -
	
	override init(dirPath: String) {
		super.init(dirPath: dirPath)

		loadChannels()
		printChannelsWithNoRecentPublications(delayInDays: 15)
	}

	private func loadChannels() {
		let files = try! FileManager.default.contentsOfDirectory(	at: URL(fileURLWithPath: dirPath),
																								includingPropertiesForKeys:nil,
																								options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
		for file in files {
			if file.lastPathComponent.hasPrefix("channel-") == false || file.pathExtension != "plist" {
				continue
			}
			if let channel = YtChannel.channel(fromFile: file.path) {
				channels.append(channel)
			}
			else {
				THLogError("channel == nil file:\(file)")
			}
		}

		THLogInfo("\(channels.count) channels")
	}
	
	// MARK: -
	
	private func printChannelsWithNoRecentPublications(delayInDays: Int) {

		let now = Date().timeIntervalSinceReferenceDate
		let timeRef = now - TimeInterval(delayInDays).th_day
		var printables = [YtChannel]()

		for channel in channels {
			guard let recentFeed = channel.items.first?.received
			else {
				continue
			}

			if recentFeed.timeIntervalSinceReferenceDate > timeRef  {
				continue
			}
			
			printables.append(channel)
		}
	
		printables.sort(by: { $0.items.first!.received <  $1.items.first!.received })
		let p = printables.map({ "\($0.items.first!.received), \($0.title!)" })

		THLogInfo("channel without recent (15 days) publication:\(p as NSArray)")
	}

	// MARK: -

	func addChannel(videoId: YtChannelVideoId) -> Bool {
		if self.channel(withVideoId: videoId) != nil {
			THLogError("another channel found with videoId:\(videoId)")
			return false
		}

		let channel = YtChannel(videoId: videoId)
		channels.append(channel)

		if channel.save(toDir: dirPath) == false {
			THLogError("save == false channel:\(channel)")
		}

		return true
	}

	func refresh(force: Bool = false) {
		if force == true {
			for channel in channels {
				channel.lastUpdate = nil
			}
		}
		startUpdateOfNextChannel()
	}

	// MARK: -

	func channelsOnError() -> [YtChannel]? {
		let r = channels.filter( { $0.lastError != nil } )
		return r.isEmpty ? nil : r
	}

	func channel(withVideoId videoId: YtChannelVideoId) -> YtChannel? {
		return channels.first(where: { $0.videoId == videoId })
	}

	override func channel(withId identifier: String) -> Channel? {
		channels.first(where: { $0.identifier == identifier } )
	}

	override func recentRefDate() -> TimeInterval {
		Date().timeIntervalSinceReferenceDate - 1.5.th_day
	}

	override func removeChannel(_ channelId: String) {
		super.removeChannel(channelId)
		channels.removeAll(where: {$0.identifier == channelId })
	}

	func hasUnreaded() -> Bool {
		channels.contains(where: { $0.hasUnreaded()})
	}

	func unreadedCount() -> Int {
		var r = 0
		for channel in channels.filter( { $0.disabled == false } ) {
			r += channel.unreaded()
		}
		return r
	}

//	func unreadedChannels() -> [YtChannel] {
//		let channels = self.channels.filter( { $0.disabled == false && $0.hasUnreaded() } )
//		return channels.sorted(by: {
//			if let p0 = $0.items.first?.wallDate, let p1 = $1.items.first?.wallDate {
//				return p0 > p1
//			}
//			return false
//		})
//	}

//	func recentChannels(afterDate dateRef: TimeInterval) -> [YtChannel] {
//		let channels = self.channels.filter( { $0.disabled == false && $0.hasRecent(refDate: dateRef) } )
//		return channels.sorted(by: {
//			if let p0 = $0.items.first?.wallDate, let p1 = $1.items.first?.wallDate {
//				return p0 > p1
//			}
//			return false
//		})
//	}

	// MARK: -
	
	func startUpdateOfNextChannel() {
		if channels.contains(where: { $0.isUpdating == true }) == true {
			return
		}

		guard let channel = channels.first(where: { $0.disabled == false && $0.shouldUpdate() == true })
		else {
			return
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
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
