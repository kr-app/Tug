// YtChannelManager.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
struct YtChannelFilter {

	static let shared = YtChannelFilter()

	func ruleFor(channel: YtChannel, item: ChannelItem) -> Int {

		if channel.videoId.identifier == "UC2MGuhIaOP6YLpUx106kTQw" { //International Federation of Sport Climbing
			if let title = item.title {

				if title.lowercased().contains("Paraclimbing".lowercased()) == true {
					return 1
				}

				for sf in [	" Lead highlights",
								" Speed highlights",
								" Lead qualifications highlights",
								" Boulder highlights",
								" Highlights"] {
					if title.lowercased().hasSuffix(sf.lowercased()) == true {
						return 1
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
						return 1
					}
				}
			}
		}
		else if channel.videoId.identifier == "UC__xRB5L4toU9yYawt_lIKg" { // BLAST
			if let title = item.title {
				if title.hasSuffix("- LE JOURNAL") == true {
					return 1
				}
			}
		}

		return 0
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
