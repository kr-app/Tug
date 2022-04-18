// ChannelDataTransformer.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
struct ChannelDataTransformer {

	static func transform(title: String?) -> String? {
		var nTitle = title
		while nTitle?.contains("  ") == true {
			nTitle = nTitle?.replacingOccurrences(of: "  ", with: " ")
		}
		return nTitle
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
