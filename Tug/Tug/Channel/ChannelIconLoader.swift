// ChannelIconLoader.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class ChannelIconLoader: NSObject {
	static let shared = ChannelIconLoader()

	private(set) var iconDownloader: THIconDownloader!

	override init() {
		super.init()

		iconDownloader = THIconDownloader(directory: FileManager.th_appCachesDir("THIconDownloader-ChannelManager"))
		iconDownloader.configuration.retention = 30.0.th_day
		iconDownloader.configuration.maxSize = 84.0
		iconDownloader.configuration.cropIcon = true
		//iconDownloader.configuration.excludedHosts = ["static.latribune.fr"]
		iconDownloader.configuration.inMemory = 30

		NotificationCenter.default.addObserver(self, selector: #selector(n_channelUpdated), name: ChannelManager.channelUpdatedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(n_channelItemUpdated), name: ChannelManager.channelItemUpdatedNotification, object: nil)
	}

	func cleanIconDownloader() {
		//iconDownloader.cleanMemory()
	}

	@objc private func n_channelUpdated(_ notification: Notification) {
		let channel = notification.userInfo!["channel"] as! Channel
		//let item = notification.userInfo!["item"] as? ChannelItem

		for item in channel.visibleItems {
			if item.checked == true || iconDownloader.hasData(forIconUrl: item.thumbnail) == true {
				continue
			}
			iconDownloader.loadIcon(atURL: item.thumbnail)
		}
	}

	@objc private func n_channelItemUpdated(_ notification: Notification) {
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
