// RssChannelItem.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class RssChannelItem: ChannelItem {

	var articleImage: RssArticleImage?

	override init() {
		super.init()
	}

	override func dictionaryRepresentation() -> THDictionaryRepresentation {
		let coder = super.dictionaryRepresentation()
		coder.setString(identifier == link?.absoluteString ? "LINK" : identifier, forKey: "identifier")
		return coder
	}

	required init(withDictionaryRepresentation dictionaryRepresentation: THDictionaryRepresentation) {
		super.init(withDictionaryRepresentation: dictionaryRepresentation)

		if identifier == "LINK" {
			identifier = link!.absoluteString
		}

	}
}
//--------------------------------------------------------------------------------------------------------------------------------------------
