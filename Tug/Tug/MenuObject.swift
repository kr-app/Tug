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
	var tooltip: String?

	var rowHeight: CGFloat {
		switch self.kind {
		case .rss, .yt:
			return 88.0
		case .separator:
			return 19.0
		case .group:
			return 24.0
		case .error:
			return 57.0
		}
	}

}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------
