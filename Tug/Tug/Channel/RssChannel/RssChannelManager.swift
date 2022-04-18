// RssChannelManager.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class RssChannelManager: ChannelManager {

	static let shared = RssChannelManager(dirPath: FileManager.th_documentsPath("RssChannels"))
	override class var channelClass: AnyClass { RssChannel.self }

	// MARK: -

	@discardableResult func addChannel(url: URL, startUpdate: Bool = true) -> RssChannel? {
		if channel(withUrl: url) != nil {
			THLogError("another channel found with url:\(url.absoluteString)")
			return nil
		}

		let channel = RssChannel(url: url)
		addChannel(channel, startUpdate: startUpdate)

		return channel
	}

	override func reloadAll() {
		RssChannelFilterManager.shared.synchronizeFromDisk()
		super.reloadAll()
	}

	override func refresh() {
		RssChannelFilterManager.shared.synchronizeFromDisk()
		super.refresh()
	}
	
	// MARK: -
	
	override func recentRefDate() -> TimeInterval {
		Date().timeIntervalSinceReferenceDate - 0.66.th_day
	}

	func hasWallChannels(withDateRef dateRef: TimeInterval, atLeast: Int) -> Bool {
		var nb = 0
		for channel in channels.filter({ $0.disabled == false }) {
			nb += channel.visibleItems.filter( { $0.checkedDate == nil && $0.isRecent(refDate: dateRef) }).count
			if nb >= atLeast {
				return true
			}
		}
		return false
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
