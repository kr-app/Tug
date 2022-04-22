//  Tools.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
func OpenWebLink(_ webLink: URL) {
	DispatchQueue.main.async {
		let win = THWebBrowserScriptingTools.createWindowIfNecessary(page: webLink)
		if win == 1 {
			return
		}
		else if win == 0 {
			THOpenInBrowser.shared.open(url: webLink, completion: {(ok: Bool) in
				if ok == false {
					THLogError("open == false link:\(webLink)")
				}
			})
		}
		else {
			THLogError("failed to open webLink:\(webLink)")
		}
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
