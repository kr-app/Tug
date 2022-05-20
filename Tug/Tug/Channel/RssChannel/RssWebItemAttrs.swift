// RssWebItemAttrs.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class RssWebItemAttrs {
	static let didUpdateAttributeNotification = Notification.Name("RssWebItemAttrs-didUpdateAttributeNotification")

	private static let urlSession = URLSession(configuration: URLSessionConfiguration.th_ephemeral())
	
	private static var items = [RssWebItemAttrs]()
	private static var invalidHosts = [String]()
	
	var link: URL!
	var extractedImage: URL?

	private var task: URLSessionTask?

	static func canStart(for link: URL) -> Bool {
		guard let host = link.host
		else {
			return false
		}
		if ["tass.com"].contains(host) {
			return false
		}
		return Self.invalidHosts.contains(host) == false
	}

	static func item(for link: URL) -> RssWebItemAttrs? {
		items.first(where: { $0.link == link })
	}

	init(link: URL) {
		self.link = link
	}

	func start(_ completion: @escaping (Bool, String?) -> Void) {
		THLogInfo("link:\(link.absoluteString)")
		Self.items.append(self)

		let request = URLRequest(url: link, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30.0)

		task = Self.urlSession.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
			if self.task == nil {
				THLogInfo("cancelled")
				return
			}

			if let rep = response as? HTTPURLResponse, let data = data {
				if rep.statusCode == 200 {

					if let html = String(data: data, encoding: .utf8) {
						if let image = THWebPageOgAttrs.extractImage(html) {
							self.removeToInvalidHost()
							self.extractedImage = image
						//	let json = THWebPageJsonLdAttrs.extract(html)
							DispatchQueue.main.async {
								completion(true, nil)
								NotificationCenter.default.post(name: Self.didUpdateAttributeNotification, object: self, userInfo: ["thumbnailUrl": image])
							}
							return
						}
					}

					data.writeDebugOutput(to: FileManager.th_appCachesDir("RssWabItemAttrs").th_appendingPathComponent("\(self.link.host!).html"))

					self.addToInvalidHost()
					DispatchQueue.main.async {
						completion(false, "og image not found")
					}

					return
				}
			}

			//self.addToInvalidHost()
			let errorMsg = error?.localizedDescription ?? (response as? HTTPURLResponse)?.th_displayStatus()
			DispatchQueue.main.async {
				THLogError("request:\(request.url?.absoluteString), error:\(errorMsg)")
				completion(false, errorMsg)
			}
		})
		task!.resume()
	}

	private func addToInvalidHost() {
		guard let invalidHost = link.host else { return }
	
		if Self.invalidHosts.contains(invalidHost) == false {
			Self.invalidHosts.append(invalidHost)
		}
	}

	private func removeToInvalidHost() {
		if let invalidHost = link.host, Self.invalidHosts.contains(invalidHost) {
			Self.invalidHosts.removeAll(where: { $0 == invalidHost })
		}
	}
	func stop() {
		task?.cancel()
		task = nil
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
