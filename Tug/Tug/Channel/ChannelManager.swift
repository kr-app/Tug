//  ChannelManager.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class ChannelManager: NSObject {

	static let channelUpdatedNotification = Notification.Name("ChannelManager-channelUpdatedNotification")
	static let channelItemUpdatedNotification = Notification.Name("ChannelManager-channelItemUpdatedNotification")

	class var channelClass: AnyClass { THFatalError("n/i") }

	var dirPath: String
	let urlSession = URLSession(configuration: URLSessionConfiguration.th_ephemeral())
	private(set) var channels = [Channel]()

	init(dirPath: String) {
		self.dirPath = dirPath
		super.init()
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

			if let channel = (Self.channelClass as! Channel.Type).channel(fromFile: file.path) {
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

		var nbOnError = 0
		channels.forEach({ nbOnError += ($0.lastError != nil) ? 1 : 0 })

		var nbDisabled = 0
		channels.forEach({ nbDisabled += $0.disabled ? 1 : 0 })

		THLogInfo("\(channels.count) channels, items:\(nbItems), unreaded:\(nbUnreaded), onError:\(nbOnError), disabled:\(nbDisabled)")
	}

	func channel(withId identifier: String) -> Channel? {
		channels.first(where: { $0.identifier == identifier } )
	}

	func channel(withUrl url: URL) -> Channel? {
		channels.first(where: { $0.url == url } )
	}

	func channelsOnError() -> [Channel]? {
	   let r = channels.filter( { $0.disabled == false && $0.lastError != nil } )
	   return r.isEmpty ? nil : r
	}

	internal func addChannel(_ channel: Channel, startUpdate: Bool) {
		channels.append(channel)

		if channel.save(toDir: dirPath) == false {
			THLogError("can not save channel:\(channel)")
		}

		if startUpdate == true {
			self.updateChannel(channel.identifier, completion: nil)
		}
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

		channels.removeAll(where: {$0.identifier == channelId })
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

	func reloadAll() {
		for channel in channels {
			channel.lastUpdate = nil
		}
		startUpdateOfNextChannel()
	}

	func refresh() {
		startUpdateOfNextChannel()
	}

	func startUpdateOfNextChannel() {
		if channels.contains(where: { $0.isUpdating == true }) == true {
			return
		}

		guard let channel = channels.first(where: { $0.disabled == false && $0.shouldUpdate() == true })
		else {
			return
		}

		if THNetworkStatus.hasNetwork() == false {
			THLogWarning("no network available")
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

	func hasUnreaded() -> Bool {
		channels.contains(where: { $0.disabled == false && $0.hasUnreaded()})
	}

	func unreadedCount() -> Int {
		var r = 0
		for channel in channels.filter( { $0.disabled == false } ) {
			r += channel.unreaded()
		}
		return r
	}

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

	func deleteItem(_ item: ChannelItem, channel channelId: String) {
		guard let channel = channel(withId: channelId)
		else {
			return
		}

		for item in channel.items.filter({ $0.identifier == item.identifier }) {
			item.userDeleted = true
		}

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
