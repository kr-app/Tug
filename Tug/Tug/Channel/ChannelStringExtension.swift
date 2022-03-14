// ChannelStringExtension.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
extension String {

	func th_purifiedHtmlBestAsPossible() -> String {

		if self.range(of: "<") == nil {
			return self
		}
		
		var nc  = ""
		var opened = 0
		var charCount = 1
		let maxChars = 300
		
		for (_, ch) in self.enumerated() {
			if ch == "<" {
				opened += 1
				continue
			}
			if ch == ">" {
				opened -= 1
				continue
			}
			
			if opened > 0 {
				continue
			}

			charCount += 1
			if charCount > maxChars {
				break
			}
			nc += String(ch)
		}

//					let das = try NSAttributedString(		data: c.data(using: .unicode)!,
//																			options: [.documentType: NSAttributedString.DocumentType.html],
//																			documentAttributes: nil)
//					content = das.string
//				}
//				catch {
//					THLogError("can not created attributed string from content:\(c) error: \(error)")
//				}
			
		return nc
	}

	func th_trimEmoji() -> String {
		return self.unicodeScalars.filter { !$0.properties.isEmojiPresentation }.reduce("") {
			$0 + String($1)
		}
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
