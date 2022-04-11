// RssChannelManager.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class RssChannelManager: ChannelManager {

	static let shared = RssChannelManager(dirPath: FileManager.th_documentsPath("RssChannels"))
	override class var channelClass: AnyClass { RssChannel.self }

	var filterManager: RssChannelFilterManager?
	
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

	func hasWallChannels(withDateRef dateRef: TimeInterval, atLeast: Int) -> Bool {
		var nb = 0
		for channel in channels.filter({ $0.disabled == false }) {
			nb += channel.items.filter( {$0.checkedDate == nil && $0.isRecent(refDate: dateRef) }).count
			if nb >= atLeast {
				return true
			}
		}
		return false
	}

	// MARK: -

	private func startUpdateOfNextChannel() {
		if channels.contains(where: { $0.isUpdating == true }) == true {
			return
		}

		let channels = self.channels.sorted(by: {
					if $0.lastUpdate == nil || $1.lastUpdate == nil {
						return true
					}
					return $0.lastUpdate! < $1.lastUpdate!
				})

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
