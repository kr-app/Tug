// YtChannel.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class YtChannel: Channel {

	private(set) var videoId: YtChannelVideoId!
	private var excludedItems = [String]()

	override var description: String {
		th_description("identifier:\(identifier) videoId:\(videoId) title:\(title)")
	}

	init(videoId: YtChannelVideoId) {
		super.init()

		self.identifier = UUID().uuidString
		self.videoId = videoId
		self.onCreation = true

		THLogDebug("created new \(self)")
	}

	override class func channel(fromFile path: String) -> Self? {
		let channel = Self.th_unarchive(fromDictionaryRepresentationAtPath: path)
		channel?.identifier = String(path.th_lastPathComponent.th_deletingPathExtension.dropFirst("channel-yt-".count))
		return channel
	}
	
	override func getFilename(withExt ext: String) -> String {
		return "channel-yt-\(identifier)".th_appendingPathExtension(ext)
	}

	override func dictionaryRepresentation() -> THDictionaryRepresentation {
		let coder = super.dictionaryRepresentation()
		coder.setObject(videoId, forKey: "videoId")
		return coder
	}
	
	required init(withDictionaryRepresentation dictionaryRepresentation: THDictionaryRepresentation) {
		super.init(withDictionaryRepresentation: dictionaryRepresentation)

		items = YtChannelItem.th_objects(fromDictionaryRepresentation: dictionaryRepresentation, forKey: "items") ?? YtChannelItem.th_objects(fromDictionaryRepresentation: dictionaryRepresentation, forKey: "feeds") ?? []

		videoId = YtChannelVideoId.th_object(fromDictionaryRepresentation: dictionaryRepresentation, forKey: "videoId")!
	}

	override func displayName() -> String {
		title ?? link?.th_reducedHost ?? "nil"
	}

	override func updateRequest() -> URLRequest {
		return URLRequest(url: videoId.url(), cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15.0)
	}

	func shouldUpdate() -> Bool {

		guard let lu = lastUpdate
		else {
			return true
		}

		let luNow = lu.timeIntervalSinceNow

		// moins de 15 min -> false
		if luNow > -15.th_min {
			return false
		}

		let items = self.items.sorted(by: { ($0.published ?? $0.received)!  >  ($1.published ?? $1.received)! })
		if items.isEmpty == true {
			return luNow < -1.th_hour
		}

		// plus de 15 jours -> 1 update / jour
		let last = (items[0].published ?? items[0].received)!.timeIntervalSinceNow
		if last < -15.th_day {
			return luNow < -1.th_hour
		}

		if title == "ARTE Découverte" || title == "ARTE" {
			return luNow < -1.th_day
		}

		if items.count > 2 {
			let last = (items[0].published ?? items[0].received)!.timeIntervalSinceReferenceDate
			let lastn1 = (items[1].published ?? items[1].received)!.timeIntervalSinceReferenceDate
			let lastn2 = (items[2].published ?? items[2].received)!.timeIntervalSinceReferenceDate

			let normal = min(last - lastn1, lastn1 - lastn2)
			let normalDay = normal / 1.th_day

			// le dernier + la moitier du temps normal -> 1 par jour
			if (last + (normal / 2.0)) > Date().timeIntervalSinceReferenceDate {
				return luNow < -1.th_hour
			}

			if normalDay >= 3.0 {
				return luNow < -1.th_hour
			}
		}

		return luNow < -15.th_min
	}

	override func parse(data: Data) -> String? {

#if DEBUG
		let cachesDir = FileManager.th_appCachesDir("YtChannel")
		let filename = getFilename(withExt: "xml")
		let p = cachesDir.th_appendingPathComponent(filename)

		if TH_isDebuggerAttached() == true {
			try! data.write(to: URL(fileURLWithPath: p))
		}
		else if FileManager.default.fileExists(atPath: cachesDir) == true {
			if FileManager.default.th_removeItem(atPath: cachesDir) == false {
				THLogError("th_removeItem == false cachesDir:\(cachesDir)")
			}
		}
#endif

		let options = THXMLParserOptions_recover
		guard let parser = THXMLParser(data: data, baseURL: nil, options: options)
		else {
			THLogError("can not init THXMLParser")
			return THLocalizedString("can not init parser")
		}
	
		guard let rn = parser.rootElement()
		else {
			THLogError("can not get rootElement")
			return THLocalizedString("can not get root node")
		}
	
		guard 	//let feedNode = rn.childs()?.first,//?.childs()?.first,
					let childs = rn.childs()
					//feedNode.name() == "feed"
		else {
			THLogError("feedNode == nil || childs == nil ")
			return THLocalizedString("can not init parser")
		}

		let isoDateFormatter = ISO8601DateFormatter()
		var nbItems = 0
		let nowDate = Date()
	
		for c in childs {
			if c.name() == "title" {
				if let title = c.childs()?.first?.content() {
					self.title = title
				}
			}
			else if c.name() == "link" {
				if let link = c.attribute(forKey: "href") as? String {
					self.link = URL(string: link)
				}
			}
			else if c.name() == "entry" {

				nbItems += 1

				guard let identifier = c.childNamed("id")?.childs()?.first?.content()
				else {
					THLogError("identifier == nil c:\(c)")
					continue
				}
				
				let title = c.childNamed("title")?.childs()?.first?.content()
				let link = c.childNamed("link")?.attribute(forKey: "href") as? String
				let published = c.childNamed("published")?.childs()?.first?.content()
				let updated = c.childNamed("updated")?.childs()?.first?.content()
				
				let group = c.childNamed("group")
				var thumbnail = group?.childNamed("thumbnail")?.attribute(forKey: "url") as? String
				let contentText = group?.childNamed("description")?.childs()?.first?.content()

				var views: Int?
				if let viewsStr = group?.childNamed("community")?.childNamed("statistics")?.attribute(forKey: "views") as? String {
					views = Int(viewsStr)
				}

				// live en attente…
				if views == 0 {
					THLogWarning("entry with identifier:\(identifier) title:\(title) excluded because zero view (LIVE)")
					continue
				}

				if thumbnail != nil && thumbnail?.th_lastPathComponent == "hqdefault.jpg" {
					thumbnail = thumbnail?.th_deletingLastPathComponent.th_appendingPathComponent("mqdefault.jpg")
				}

				var publishedDate = published != nil ? isoDateFormatter.date(from: published!) : nil
				if publishedDate == nil {
					THLogWarning("can not found published date c:\(c)")
				}
				var updatedDate = updated != nil ? isoDateFormatter.date(from: updated!) : nil
				if updatedDate == nil {
					THLogWarning("can not found updated date c:\(c)")
				}
				
				if publishedDate == nil && updatedDate != nil {
					publishedDate = updatedDate
				}
				else if updatedDate == nil && publishedDate != nil {
					updatedDate = publishedDate
				}

				let old_feed = items.first(where: { $0.identifier == identifier })

				let received: Date!
				if onCreation == true {
					received = updatedDate ?? publishedDate ?? nowDate
				}
				else {
					received = old_feed?.received ?? nowDate
				}

				if excludedItems.contains(where: { $0 == identifier }) {
					continue
				}

				let rule = YtChannelFilter.shared.ruleFor(channel: self, itemTitle: title, itemContentText: contentText, itemViews: views)
				if rule == .ignore {
					excludedItems.append(identifier)
					THLogWarning("channel:\(self.title) ignore item:\(title)")
					continue
				}
				else if rule == .ignoreTemporaly {
					THLogWarning("channel:\(self.title) ignore temporaly item:\(title)")
					continue
				}

				let item = YtChannelItem(identifier: identifier, received: received)

				item.published = old_feed?.published ?? publishedDate
//				item.updated = updatedDate ?? old_feed!.updated ?? Date()

				item.title = YtChannelDataTransformer.transform(title: title, forChannel: videoId)
				item.link = link != nil ? URL(string: link!) : nil
				item.contentText = YtChannelDataTransformer.transform(contentText: contentText, forChannel: videoId)
				item.thumbnail = thumbnail != nil ? URL(string: thumbnail!) : nil
				item.views = views

				if let old_feed = old_feed {
					items.removeAll(where: { $0.identifier == identifier})
					item.checkedDate = old_feed.checkedDate
				}

				if rule == .markReaded {
//					log(.info, "excluded item:\(item)")
					item.checkedDate = nowDate
				}

				items.append(item)
				items.sort(by: { $0.received >  $1.received })
			}
		}

		onCreation = false
//		nbReceivedItems = nbItems

		if markAllRead == true {
			markAllRead = false
			items.forEach({ $0.checkedDate = nowDate })
		}

		if items.count > 100 {
			items.removeLast(items.count - 100)
		}

		return nil
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
