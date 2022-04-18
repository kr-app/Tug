// YtChannelDataTransformer.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
struct YtChannelDataTransformer {

	static func transform(title: String?, forChannel videoId: YtChannelVideoId) -> String? {
		guard let title = title else { return nil }

		if videoId.kind == .channelId && videoId.identifier == "UCgGb7tN3tIH5_Kk05D1J_bA" { // RMC
			let p = "🔴 EN DIRECT - "
			if title.hasPrefix(p) {
				return title.th_trimPrefix(p)
			}
		}

		return title
	}

	static func transform(contentText: String?, forChannel videoId: YtChannelVideoId) -> String? {
		guard let contentText = contentText else { return nil }

		var text = contentText.th_truncate(max: 300, substitutor: nil)

		if videoId.kind == .channelId && videoId.identifier == "UCgGb7tN3tIH5_Kk05D1J_bA" { // RMC
			let p = "🔴 EN DIRECT - "
			if text.hasPrefix(p) {
				text = text.th_trimPrefix(p)
			}
		}

		text = text.replacingOccurrences(of: "\n\n", with: "\n")

		while text.hasPrefix("-") {
			text = String(text.dropFirst())
		}

		while text.hasPrefix("\n") {
			text = String(text.dropFirst())
		}

		return text
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
