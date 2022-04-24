// YtChannelManager.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
enum YtChannelFilterRule {
	case include
	case markReaded
	case ignore
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
struct YtChannelFilter {

	static let shared = YtChannelFilter()

	func ruleFor(channel: YtChannel, itemTitle: String?, itemContentText: String?, itemViews: Int?) -> YtChannelFilterRule {

		let videoId = channel.videoId!

		if videoId.kind == .channelId && videoId.identifier == "UC2MGuhIaOP6YLpUx106kTQw" { // International Federation of Sport Climbing
			if let title = itemTitle?.lowercased() {
				// contains
				if title.contains("Paraclimbing".lowercased()) || title.contains(" highlights || ") {
					return .markReaded
				}
				// suffix
				for sf in ["highlights"] {
					if title.hasPrefix(" \(sf)") {
						return .markReaded
					}
				}
			}
		}
		else if videoId.kind == .channelId && videoId.identifier == "UC__xRB5L4toU9yYawt_lIKg" { // BLAST
			if let title = itemTitle {
				if title.hasSuffix("- LE JOURNAL") {
					return .ignore
				}
			}
		}
		else if videoId.kind == .channelId && videoId.identifier == "UCgGb7tN3tIH5_Kk05D1J_bA" { // RMC
			if let title = itemTitle {
				if title.contains("EN DIRECT") || title.hasSuffix("invité de RMC") || title.contains("Apolline de Malherbe") {
					return .include
				}
				return .ignore
			}
		}
		else if videoId.kind == .channelId && videoId.identifier == "UCMRJqoSRIaakAJUJK104Z8Q" { // Touche pas à mon poste !
			if let views = itemViews {
				if views > 100_000 {
					return .include
				}
			}
			return .ignore
		}
		else if videoId.kind == .channelId && videoId.identifier == "UCESTwDXpoMgiYBHipMdKTkQ" { // Sud Radio
			if let views = itemViews {
				if views > 25_000 {
					return .include
				}
			}
			return .ignore
		}
		else if videoId.kind == .channelId && videoId.identifier == "UCV6YKhpI0Bs5hSJ6frXM4nA" { // Y a que la vérité qui compte
			if let description = itemContentText {
				if description.contains("#shorts") {
					return .ignore
				}
			}
		}
		else if channel.title == "Skating ISU" {
			if let title = itemTitle {
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
		else if let title = itemTitle {
			if title.contains("#short") || title.contains("#shorts") || title.contains("#Short") {
				return .ignore
			}
		}

		return .include
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
