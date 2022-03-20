//  ChannelManager.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class ChannelManager: NSObject {

	static let channelUpdatedNotification = Notification.Name("ChannelManager-channelUpdatedNotification")
	static let channelItemUpdatedNotification = Notification.Name("ChannelManager-channelItemUpdatedNotification")

	let dirPath: String
	let urlSession = URLSession(configuration: URLSessionConfiguration.th_ephemeral())

	init(dirPath: String) {
		self.dirPath = dirPath
	}

	func channel(withId: String) -> Channel? {
		return nil
	}

	func channelsOnError() -> [Channel]? {
		THFatalError("not implemented")
	}

	func removeChannel(_ channelId: String) {
		guard let channel = channel(withId: channelId)
		else {
			return
		}

		channel.cancel()
		if channel.trashFile(fromDir: dirPath) == false {
			THLogError("can not trash channel:\(channel)")
		}
	}

	func recentRefDate() -> TimeInterval {
		THFatalError("not implemented")
	}

	func synchronise(channel: Channel, immediately: Bool = false) {
		channel.synchronise(dirPath: dirPath, immediately: immediately)
	}

	func noteChange(channel: Channel, item: ChannelItem? = nil) {
		if let item = item {
			NotificationCenter.default.post(name: Self.channelItemUpdatedNotification, object: self, userInfo: ["channel": channel, "item": item.identifier])
			return
		}

		NotificationCenter.default.post(name: Self.channelUpdatedNotification, object: self, userInfo: ["channel": channel])
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
extension ChannelManager {

	func setAttribute(disabled: Bool? = nil, url: URL? = nil, channel channelId: String) {
		guard let channel = channel(withId: channelId)
		else {
			return
		}

		if let disabled = disabled {
			channel.disabled = disabled
		}
		else if let url = url {
			channel.url = url
		}

		synchronise(channel: channel)
		noteChange(channel: channel)
	}

	func clean(channel channelId: String) {
		guard let channel = channel(withId: channelId)
		else {
			return
		}

		channel.items.removeAll()

		synchronise(channel: channel)
		noteChange(channel: channel)
	}

	func updateChannel(_ channelId: String, completion: (() -> Void)?) {
		guard let channel = channel(withId: channelId)
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

			completion?()
			NotificationCenter.default.post(name: Self.channelUpdatedNotification, object: self, userInfo: ["channel": channel])
		})
	}
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
extension ChannelManager {

	func mark(checked: Bool? = nil, pinned: Bool? = nil, item: ChannelItem, channel channelId: String) {
		guard let channel = channel(withId: channelId)
		else {
		   return
		}

		guard let r_item = channel.items.first(where: {$0.identifier == item.identifier })
		else {
		   return
		}

		if let checked = checked {
			if item.checked == checked {
				return
			}

			item.checkedDate = checked ? Date() : nil
			r_item.checkedDate = item.checkedDate
		}
		else if let pinned = pinned {
			if item.pinned == pinned {
				return
			}

			item.pinndedDate = pinned ? Date() : nil
			r_item.pinndedDate = item.pinndedDate
		}

		synchronise(channel: channel)
		noteChange(channel: channel, item: item)
	}

	func removeItem(_ item: ChannelItem, channel channelId: String) {
		guard let channel = channel(withId: channelId)
		else {
			return
		}

		channel.items.removeAll(where: {$0.identifier == item.identifier })

		synchronise(channel: channel, immediately: true)
		noteChange(channel: channel)
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
extension ChannelManager {

	func pathOfChannel(_ channel: Channel?, item: ChannelItem? = nil) -> String? {
		guard let channel = channel
		else {
			return nil
		}

		let path = "/" + Self.th_className + "/" + channel.identifier!
		if let item = item {
			return path + "/" + item.identifier
		}
		return path
	}

	func revealFile(channel channelId: String) {
		guard let channel = channel(withId: channelId)
		else {
			return
		}

		let fileUrl = channel.getFileUrl(dirPath: dirPath)
		NSWorkspace.shared.activateFileViewerSelecting([fileUrl])
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
extension ChannelManager {

	static func managerOfChannel(_ channel: Channel?) -> ChannelManager? {
		guard let channel = channel
		else {
			return nil
		}
		return channel is RssChannel ? RssChannelManager.shared : channel is YtChannel ? YtChannelManager.shared : nil
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
