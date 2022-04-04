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
			//return channels.contains(where: { $0.hasUnreaded() && $0.hasRecent(refDate: dateRef) } )
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
