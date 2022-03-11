// MenuObject.swift

import Cocoa

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------
enum MenuObjectKind {
	case rss
	case yt
	case separator
	case error
}

struct MenuObjectItem {
	let kind: MenuObjectKind
	var channel: Channel?
	var item: ChannelItem?
	var error: String?
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------
