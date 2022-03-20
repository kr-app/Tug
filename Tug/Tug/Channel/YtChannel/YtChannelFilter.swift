// YtChannelManager.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
enum YtChannelFilterRule {
	case none
	case markReaded
	case ignore
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
struct YtChannelFilter {

	static let shared = YtChannelFilter()

	func ruleFor(channel: YtChannel, item: ChannelItem) -> YtChannelFilterRule {

		let videoId = channel.videoId!

		if videoId.identifier == "UC2MGuhIaOP6YLpUx106kTQw" { //International Federation of Sport Climbing
			if let title = item.title {
				if title.lowercased().contains("Paraclimbing".lowercased()) == true {
					return .markReaded
				}
				for sf in [	" Lead highlights",
								" Speed highlights",
								" Lead qualifications highlights",
								" Boulder highlights",
								" Highlights"] {
					if title.lowercased().hasSuffix(sf.lowercased()) == true {
						return .markReaded
					}
				}
			}
		}
		else if channel.title == "Skating ISU" {
			if let title = item.title {
				for sf in [	"| Men FS |",
								"Men Short Program |",
								"Ice Dance Free Dance |",
								"| Pairs FS |",
								"Pairs Short Program |",
								"| Ice Dance RD |",
								"| 1000m ",
								"| 2000m ",
								"| 3000m "] {
					if title.contains(sf) == true {
						return .markReaded
					}
				}
			}
		}
		else if channel.title == "Geo History" {
			if let title = item.title {
				if title.hasSuffix(" - #Shorts") == true {
					return .ignore
				}
			}
		}
		else if videoId.kind == .channelId && videoId.identifier == "UC__xRB5L4toU9yYawt_lIKg" { // BLAST
			if let title = item.title {
				if title.hasSuffix("- LE JOURNAL") == true {
					return .ignore
				}
			}
		}
		else if videoId.kind == .channelId && videoId.identifier == "UCgGb7tN3tIH5_Kk05D1J_bA" { // RMC
			if let title = item.title {
				if title.contains("EN DIRECT") && title.hasSuffix("invité de RMC") {
					return .none
				}
				return .ignore
			}
		}

		return .none
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
