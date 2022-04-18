// RssChannelDataTransformer.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
struct RssChannelDataTransformer {

	static func transform(contentText: String?) -> String? {
		guard let contentText = contentText else { return nil }

		var text = contentText.th_truncate(max: 300, substitutor: nil)
		text = text.replacingOccurrences(of: "\n\t", with: "\n")

		return text
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
