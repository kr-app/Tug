// PubDateConvertor.swift

import Cocoa
import UniformTypeIdentifiers

//--------------------------------------------------------------------------------------------------------------------------------------------
class PubDateConvertor {
	
	private let df_iso = ISO8601DateFormatter()
	private let df_alt0 = DateFormatter(dateFormat: "E, d MMM yyyy HH:mm:ss Z")
	private let df_alt1 = DateFormatter(dateFormat: "E, dd MMM yyyy HH:mm:ss zzz")
	private let df_alt2 = DateFormatter(dateFormat: "E, dd MMM yyyy HH:mm:ss")
	
	private var df_alt2_tz: TimeZone?
	private var onErrorOnce = false
	
	func pubDate(from string: String) -> Date? {
		
		if let date = df_iso.date(from: string) {
			return date
		}

		if let date = df_alt0.date(from: string) {
			return date
		}

		if let date = df_alt1.date(from: string) {
			return date
		}

		let nbChars = string.count
		if nbChars > 10 {
			if (string as NSString).range(of: " ", options: .backwards, range: NSRange(location: nbChars - 4, length: 4)).location != NSNotFound {
				if df_alt2_tz == nil {
					let tz = (string as NSString).substring(from: nbChars - 3)
					df_alt2.timeZone = TimeZone(abbreviation: tz)
				}
				if let date = df_alt2.date(from: String(string.dropLast(4))) {
					return date
				}
			}
		}

		if onErrorOnce == false {
			onErrorOnce = true
			THLogError("can not convert date from string:\(string)")
		}

		return nil
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
struct MediaUrlExtractor {

	static func urlFromEnclosure(item: THRSSFeedItem) -> String? {
		guard let url = item.value(named: "enclosure")?.attributes?["url"] as? String
		else {
			return nil
		}

		var mimeType = item.value(named: "enclosure")?.attributes?["type"] as? String
		if mimeType == nil {
			mimeType = item.value(named: "enclosure")?.attributes?["mimetype"] as? String
		}

		if let mimeType = mimeType, let type = UTType(mimeType: mimeType) {
			return type.conforms(to: .image) ? url : nil
		}

		return nil
	}

	static func urlImgSrc(fromContent content: String) -> String? {
		if content.count < 20 {
			return nil
		}

		guard let src = content.th_search(firstRangeOf: "<img src=\"", endRange: "\"")
		else {
			return nil
		}

		return URL(string: src) != nil ? src : nil
	}
}
//--------------------------------------------------------------------------------------------------------------------------------------------
