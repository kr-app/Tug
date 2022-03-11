//  ChannelManager.swift

import Foundation

//--------------------------------------------------------------------------------------------------------------------------------------------
class ChannelManager {

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

	func removeChannel(_ channelId: String) {
		guard let channel = channel(withId: channelId)
		else {
			return
		}

		channel.cancel()
		if channel.remove(fromDir: dirPath) == false {
			THLogError("can not remove channel:\(channel)")
		}
	}

	func synchronise(channel: Channel, immediately: Bool = false) {
		channel.synchronise(dirPath: dirPath, immediately: immediately)
	}

	func noteChange(channel: Channel, item: ChannelItem? = nil) {
		if let item = item {
			NotificationCenter.default.post(name: Self.channelItemUpdatedNotification, object: self, userInfo: ["channel": channel, "item": item.identifier!])
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

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
extension ChannelManager {

	func mark(checked: Bool? = nil, pinned: Bool? = nil, item: ChannelItem, channel channelId: String) {
		guard let channel = channel(withId: channelId)
		else {
		   return
		}

		guard let r_item = channel.items.first(where: {$0.identifier == item.identifier! })
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

		channel.items.removeAll(where: {$0.identifier == item.identifier! })

		synchronise(channel: channel, immediately: true)
		noteChange(channel: channel)
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
extension ChannelManager {

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
