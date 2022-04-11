// YtChannelManager.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class YtChannelManager: ChannelManager {

	static let shared = YtChannelManager(dirPath: FileManager.th_documentsPath("YtChannels"))
	override class var channelClass: AnyClass { YtChannel.self }

	// MARK: -

	func addChannel(videoId: YtChannelVideoId, startUpdate: Bool = true) -> YtChannel? {
		if self.channel(withVideoId: videoId) != nil {
			THLogError("another channel found with videoId:\(videoId)")
			return nil
		}

		let channel = YtChannel(videoId: videoId)
		channel.markAllRead = true
		addChannel(channel, startUpdate: startUpdate)

		return channel
	}

	func reloadAll() {
		for channel in channels {
			channel.lastUpdate = nil
		}
		startUpdateOfNextChannel()
	}

	func refresh() {
		startUpdateOfNextChannel()
	}

	// MARK: -

	func channel(withVideoId videoId: YtChannelVideoId) -> YtChannel? {
		return (channels as! [YtChannel]).first(where: { $0.videoId == videoId })
	}

	override func recentRefDate() -> TimeInterval {
		Date().timeIntervalSinceReferenceDate - 1.5.th_day
	}

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
