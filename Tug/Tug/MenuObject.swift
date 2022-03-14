// MenuObject.swift

import Cocoa

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------
enum MenuObjectKind {
	case rss
	case yt
	case separator
	case group
	case error
}

struct MenuObjectItem {
	let kind: MenuObjectKind
	var title: String?
	var channel: Channel?
	var item: ChannelItem?
	var error: String?
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------
