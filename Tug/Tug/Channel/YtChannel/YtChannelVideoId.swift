// YtChannelVideoId.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
enum YtChannelVideoIdKind: String {
	case channelId
	case userId
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
struct YtChannelVideoId: Equatable, CustomStringConvertible, THDictionarySerializationProtocol {
	let kind: YtChannelVideoIdKind
	let identifier: String

	var description: String { return "<\(Self.self) kind:\(kind.rawValue) identifier:\(identifier)>" }

	func dictionaryRepresentation() -> THDictionaryRepresentation {
		return THDictionaryRepresentation(values: ["kind": kind.rawValue, "identifier": identifier])
	}

	init(kind: YtChannelVideoIdKind, identifier: String) {
		self.kind = kind
		self.identifier = identifier
	}

	init(withDictionaryRepresentation dictionaryRepresentation: THDictionaryRepresentation) {
		if let kindStr = dictionaryRepresentation.string(forKey: "kind") {
			self.kind = YtChannelVideoIdKind(rawValue: kindStr)!
		}
		else {
			let kindInt = dictionaryRepresentation.int(forKey: "kind")!
			self.kind = kindInt == 0 ? .channelId : kindInt == 1 ? .userId : YtChannelVideoIdKind(rawValue: "nil")!
		}
		self.identifier = dictionaryRepresentation.string(forKey: "identifier")!
	}

	func url() -> URL {

//		UCRXiA3h1no_PFkb1JCP0yMA
//		https://www.youtube.com/feeds/videos.xml?channel_id=CHANNELID
//		https://www.youtube.com/feeds/videos.xml?user=USERID
//		https://www.youtube.com/feeds/videos.xml?playlist_id=YOUR_YOUTUBE_PLAYLIST_NUMBER

		let base = "https://www.youtube.com"

		if kind == .channelId {
			return URL(string: base + "/feeds/videos.xml?channel_id=\(identifier)")!
		}
		if kind == .userId {
			return URL(string: base + "/feeds/videos.xml?user=\(identifier)")!
		}

		THFatalError("channelId == nil && userId == nil")
	}
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
struct YtChannelVideoIdExtractor {

	// pb cookies accept
	/*class func loadVideoId(fromUrl url: URL) -> String? {

		let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 15.0)

		var response: URLResponse?
		var data: Data?
		do {
			data = try NSURLConnection.sendSynchronousRequest(request, returning: &response)
		}
		catch {
			THLogError("can not get data from url:\(url) error:\(error)")
			return nil
		}

		guard let html = String(data: data!, encoding: .utf8)
		else {
			THLogError("can not create html string from data at url:\(url)")
			return nil
		}
	}*/

	static func extractVideoId(fromSource html: String) -> YtChannelVideoId? {
		if let channelId = html.th_search(firstRangeOf: "<meta itemprop=\"channelId\" content=\"", endRange: "\"") {
			return YtChannelVideoId(kind: .channelId, identifier: channelId)
		}
		THLogError("item property not found")
		return nil
	}

	static func extractThumbnail(fromSource html: String) -> URL? {
		if let thumbnail = html.th_search(firstRangeOf: "<link rel=\"image_src\" href=\"", endRange: "\"") {
			return URL(string: thumbnail)
		}
		return nil
	}

/*	static func videoId(for site: URL) -> YtChannelVideoId? {

		let uComps = site.pathComponents
	
		if let vIdx = uComps.firstIndex(of: "channel") {
			// https://www.youtube.com/channel/UCWPOLkftHreB1p8ospsiApw/videos
			let channel = uComps[vIdx + 1]
			return YtChannelVideoId(kind: .channelId, identifier: channel)
		}
		else if uComps.count == 4 && uComps[1] == "user" {
			// https://www.youtube.com/user/AurelienDucroz/videos
			let user = uComps[uComps.count-2]
			return YtChannelVideoId(kind: .userId, identifier: user)
		}

		THLogWarning("can not extract video id from url, trying to get video id for site: \(site)")

		return nil
	}*/

}
//--------------------------------------------------------------------------------------------------------------------------------------------
