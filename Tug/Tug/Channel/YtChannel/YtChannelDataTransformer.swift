// YtChannelDataTransformer.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
struct YtChannelDataTransformer {

	static func transform(contentText: String, forChannel videoId: YtChannelVideoId) -> String? {

		var text = contentText.th_truncate(max: 200)

		if videoId.kind == .channelId && videoId.identifier == "UCgGb7tN3tIH5_Kk05D1J_bA" { // RMC
			let p = "🔴 EN DIRECT - "
			if text.hasPrefix(p) {
				text = text.th_trimPrefix(p)
			}
		}

		text = text.replacingOccurrences(of: "\n\n", with: "\n")

		return text
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
