// MenuObject.swift

import Cocoa

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------
enum ObjectKind {
	case rss
	case yt
	case separator
	case error
}

struct ObjectItem {
	let kind: ObjectKind
	var channel: Channel?
	var item: ChannelItem?
	var error: String?
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------
