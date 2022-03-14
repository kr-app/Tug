// YtChannelItem.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
struct YtChannelItemVideoLink {
	static let watchLink  = "https://www.youtube.com/watch?"
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
class YtChannelItem: ChannelItem {

	override init(identifier: String, received: Date) {
		super.init(identifier: identifier, received: received)
	}

	override func dictionaryRepresentation() -> THDictionaryRepresentation {
		let coder = super.dictionaryRepresentation()

		if let link = link?.absoluteString, link.hasPrefix(YtChannelItemVideoLink.watchLink) {
			coder.setString(String(link.dropFirst(YtChannelItemVideoLink.watchLink.count)), forKey: "link_v")
			coder.setUrl(nil, forKey: "link")
		}

		return coder
	}

	required init(withDictionaryRepresentation dictionaryRepresentation: THDictionaryRepresentation) {
		super.init(withDictionaryRepresentation: dictionaryRepresentation)

		if let link_v = dictionaryRepresentation.string(forKey: "link_v") {
			link = URL(string: YtChannelItemVideoLink.watchLink + link_v)
		}
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
