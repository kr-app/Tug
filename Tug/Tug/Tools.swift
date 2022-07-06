//  Tools.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
extension URL {

	func th_presentableUrl() -> String {
		let u = self.absoluteString
		for p in ["https://www.", "https://"] {
			if u.hasPrefix(p) {
				return u.th_trimPrefix(p)
			}
		}
		return u
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
func ExtractClipboardUrl() -> URL? {
	if let string = NSPasteboard.general.string(forType: .string) {
		if string.count > 5 && string.count < 1024 && string.contains(".") && string.contains("/") {
			return URL(string: string)
		}
	}
	return nil
}
//--------------------------------------------------------------------------------------------------------------------------------------------


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


//--------------------------------------------------------------------------------------------------------------------------------------------
func SendToMicd(_ webLink: URL/*, completion: @escaping (Bool, String?) -> Void*/) {
	guard 	let base = UserDefaults.standard.string(forKey: "sendToMicd-url-base"),
				let path = UserDefaults.standard.string(forKey: "sendToMicd-url-path")

	else {
//		UserDefaults.standard.synchronize()
		return
	}

	var urlComp = URLComponents(url: URL(string: base)!, resolvingAgainstBaseURL: false)!
	urlComp.path = path
	urlComp.queryItems = [URLQueryItem(name: "add", value: webLink.absoluteString)]

	let url = urlComp.url!
	let request = URLRequest(url: url, timeoutInterval: 15.0)
	let session = URLSession(configuration: URLSessionConfiguration.th_ephemeral())
	session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
		THLogInfo("response:\(response), error:\(error))")

		let rep = response as? HTTPURLResponse
		let ok = rep?.statusCode == 200

		DispatchQueue.main.async {
			//completion(ok, error?.localizedDescription)

			let title = "Send to micd: \(ok ? "ok" : "ko")"
			let msg = ["ok:\(ok)", "error:\(error)", "url:\(url.absoluteString)"]
			NSAlert(withTitle: title, message: msg.joined(separator: "\n"), style: ok ? .informational : .critical).runModal()
		}
	}).resume()
}
//--------------------------------------------------------------------------------------------------------------------------------------------
