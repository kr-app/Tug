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

	// MARK: -

	func channel(withVideoId videoId: YtChannelVideoId) -> YtChannel? {
		return (channels as! [YtChannel]).first(where: { $0.videoId == videoId })
	}

	override func recentRefDate() -> TimeInterval {
		Date().timeIntervalSinceReferenceDate - 1.5.th_day
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
