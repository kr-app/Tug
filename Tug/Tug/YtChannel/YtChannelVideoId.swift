// YtChannelVideoId.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
enum YtChannelVideoIdKind: Int {
	case channelId = 0
	case userId = 1
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
struct YtChannelVideoId: Equatable, THDictionarySerializationProtocol {

	let kind: YtChannelVideoIdKind
	let identifier: String

	func dictionaryRepresentation() -> THDictionaryRepresentation {
		return THDictionaryRepresentation(values: ["kind": kind.rawValue, "identifier": identifier])
	}

	init(kind: YtChannelVideoIdKind, identifier: String) {
		self.kind = kind
		self.identifier = identifier
	}

	init(withDictionaryRepresentation dictionaryRepresentation: THDictionaryRepresentation) {
		self.kind = YtChannelVideoIdKind(rawValue: dictionaryRepresentation.int(forKey: "kind")!)!
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
class YtChannelVideoIdExtractor: NSObject {

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

	class func extractVideoId(fromSource html: String) -> YtChannelVideoId? {
		let ss = html as NSString

		let rS = ss.range(of: "<meta itemprop=\"channelId\" content=\"", options: .caseInsensitive)
		if rS.location != NSNotFound {
			let rsEnd = rS.location + rS.length
			let rE = ss.range(of: "\"", options: .caseInsensitive, range: NSMakeRange(rsEnd, ss.length - rsEnd), locale: nil)
			if rE.location != NSNotFound {
				let channelId = ss.substring(with: NSMakeRange(rsEnd, rE.location - rsEnd))
				return YtChannelVideoId(kind: .channelId, identifier: channelId)
			}
		}

		THLogError("item property not found")
		return nil
	}

	class func videoId(for site: URL) -> YtChannelVideoId? {

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

//		videoId = YtChannel.loadVideoId(fromUrl: site.asURL!)
//		if videoId != nil {
//			log(.info, "found videoId:/(videoId) for site:\(site)")
//		}
//		else {
		if uComps.count == 4 && uComps[1] == "c" {
			let channelName = uComps[uComps.count-2]
			let vids = [	"MarcTouatiTV": "UCX0IqCxHb4xhdE9QPixAlfg",
								"LibreRiche": "UCmvSTbXOOvxXj26vvQBasXg",
								"CarsandEngines": "UCzaRja_k66jt-KoSBftRTgw",
								"RoCarsTV": "UCPOhQupz3MwGSIBG0OqVnAg",
								"CoupableDetout": "UCMPNysJ27EHTvLt0tGiSX0A",
								"mellowclimbing": "UC5jRwTUqG15l-BcqQHbVFtA",
								"USAClimbingOFFICIAL": "UCAthhtcB-Aa5yDg8ECTTqcA",
								"120minutesRTS": "UCmzP_xaz-uyMMbac4DggR8A",
								"MikeThurston": "UCzGLDaTu81nJDtWK10MniGg",
								"YomiDenzel": "UChgE6R4QauGAJAlYiJOcCGw",
								"BloginfluentFrance": "UCLLVFXmra3VHofacquH4EMA",
								"CNBCMakeIt": "UCH5_L3ytGbBziX0CLuYdQ1Q",
								"gabejedmo": "UCgZM50Ig7STDS0l6f_QnrXw",
								"PaulineLaigneau": "UCjsDF21AUmQGr41n6SsInEw",
								"SpacevidsTv1": "UCdF5d0UwSJJunRcRVzP1uDg",
								"YeahRussia": "UCWf43GShTqMDdJN9pICYd2Q",
								"Blast-info": "UC__xRB5L4toU9yYawt_lIKg",
								"TVMountainMontBlanc": "UCuoT1bfbPqZT_1ULPcLutaQ",
								"LeMédiaOfficiel": "UCT67YOMntJxfRnO_9bXDpvw",
								"LatexFashionTV": "UCC3iGfxG5wG17GBe1PffP0Q",
								"MSMOTORSCustom": "UCJw_IeqGUUY9ZJXVb9f-kPg",
								"VirginGalactic": "UClcvOr7LV8tlJwJvkNMmnKg"
							]

			if let id = vids[channelName] {
				return YtChannelVideoId(kind: .channelId, identifier: id)
			}
		}

		return nil
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
