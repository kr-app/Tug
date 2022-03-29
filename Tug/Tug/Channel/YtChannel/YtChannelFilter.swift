// YtChannelManager.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
enum YtChannelFilterRule {
	case include
	case markReaded
	case ignore
	case ignoreTemporaly
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
struct YtChannelFilter {

	static let shared = YtChannelFilter()

	func ruleFor(channel: YtChannel, item: ChannelItem) -> YtChannelFilterRule {

		let videoId = channel.videoId!

		if videoId.identifier == "UC2MGuhIaOP6YLpUx106kTQw" { //International Federation of Sport Climbing
			if let title = item.title {
				// contains
				if title.lowercased().contains("Paraclimbing".lowercased()) {
					return .markReaded
				}
				// suffix
				for sf in ["highlights"] {
					if title.th_hasSuffixInsensitive(" \(sf)") {
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
					if title.contains(sf) {
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
					return .include
				}
				return .ignore
			}
		}
		else if videoId.kind == .channelId && videoId.identifier == "UCESTwDXpoMgiYBHipMdKTkQ" { // Sud Radio
			if let views = item.views {
				if views > 25_000 {
					return .include
				}
			}
			return .ignoreTemporaly
		}
		else if videoId.kind == .channelId && videoId.identifier == "UCV6YKhpI0Bs5hSJ6frXM4nA" { // Y a que la vérité qui compte
			if let description = item.contentText {
				if description.contains("#shorts") {
					return .ignore
				}
			}
		}

		return .include
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
