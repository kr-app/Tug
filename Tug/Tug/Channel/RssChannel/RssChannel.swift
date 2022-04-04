// RssChannel.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class RssChannel: Channel {

	private var excludedItems = [String]()

	override class func channel(fromFile path: String) -> Self? {
		let channel = Self.th_unarchive(fromDictionaryRepresentationAtPath: path)
		channel?.identifier = path.th_lastPathComponent.th_deletingPathExtension
		return channel
	}

	// MARK: -
	
	override init() {
		super.init()

		self.creationDate = Date()
		self.identifier = UUID().uuidString
	}

	init(url: URL) {
		super.init()

		self.creationDate = Date()
		self.identifier = UUID().uuidString
		self.url = url

		THLogInfo("created new \(self)")
	}

	override var description: String {
		th_description("host:\(url?.th_reducedHost)")
	}

	// MARK: -

	required init(withDictionaryRepresentation dictionaryRepresentation: THDictionaryRepresentation) {
		super.init(withDictionaryRepresentation: dictionaryRepresentation)

		items = RssChannelItem.th_objects(fromDictionaryRepresentation: dictionaryRepresentation, forKey: "items") ?? []
	}
	
	// MARK: -

	override func displayName() -> String {
		link?.th_reducedHost ?? url?.th_reducedHost ?? url?.absoluteString ?? "nil"
	}

	// MARK: -
	
	override func updateRequest() -> URLRequest {
		return URLRequest(url: self.url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15.0)
	}
	
	override func parse(data: Data) -> String? {

#if DEBUG
		let cachesDir = FileManager.th_appCachesDir("RssChannel")
		let d_path = cachesDir.th_appendingPathComponent("\(identifier).xml")

		if TH_isDebuggerAttached() == true {
			try! data.write(to: URL(fileURLWithPath: d_path))
		}
		else if FileManager.default.fileExists(atPath: d_path) == true {
			try! FileManager.default.removeItem(atPath: d_path)
		}
#endif

		let p = THRSSFeedParser(data: data)
		if p.parse() == false {
			let pe = p.lastError
			return THLocalizedString("Can not parse RSS" + (pe != nil ? " (\(pe))" : ""))
		}

		if let title = p.generalItem.value(named: "title")?.content {
			self.title = title
		}
		if let link = p.generalItem.value(named: "link")?.content {
			self.link = URL(string: link)
		}

		let linkAsId = self.url!.host!.contains("lesechos.fr")
		var extracted_media_log_once = false
		let pubDateConvertor = PubDateConvertor()
		let nowDate = Date()

		for item in p.items {

			var title = item.value(named: "title")?.content
			while title?.contains("  ") == true {
				title = title?.replacingOccurrences(of: "  ", with: " ")
			}

			if let title = title {
				if excludedItems.contains(title) {
					continue
				}
				if RssChannelFilterManager.shared.isExcludedItem(itemTitle: title, channel: self) == true {
					THLogWarning("excluded item:\(item)")
					excludedItems.append(title)
					continue
				}
			}

			let link = item.value(named: "link")?.content
			var contentText = item.value(named: "description")?.content

			let guid = linkAsId ? nil : item.value(named: "guid")?.content
//			let guidPermaLink = item.value(named: "guid")?.attributes?["isPermaLink"] as? String

			var mediaUrl = item.value(named: "media:content")?.attributes?["url"] as? String
			let date = item.value(named: "pubDate")?.content

			let pubDate = date != nil ? pubDateConvertor.pubDate(from: date!) : nil

			if mediaUrl == nil {
				mediaUrl = MediaUrlExtractor.urlFromEnclosure(item: item)

				if mediaUrl == nil && contentText != nil {
					mediaUrl = MediaUrlExtractor.urlImgSrc(fromContent: contentText!)
					if mediaUrl != nil && extracted_media_log_once == false {
						extracted_media_log_once = true
						THLogInfo("mediaUrl:\(mediaUrl) extracted from content text for item:\(item)")
					}
				}
			}
			
			if let link = link {
				if link.contains("theskatingtimes.com") {
					mediaUrl = nil
				}
			}

			// gestion des &#039;
			if let content_cf = contentText as CFString?, let decodedHtml = CFXMLCreateStringByUnescapingEntities(nil, content_cf, nil) as? String {
				contentText = decodedHtml
			}

			// suppression des &nbsp; ?
			if contentText?.contains("&nbsp;") == true {
				contentText = contentText?.replacingOccurrences(of: "&nbsp;", with: " ")
			}

			// suppression des tags html
			contentText = contentText?.th_purifiedHtmlTagBestAsPossible()

			contentText = contentText?.th_truncate(max: 200, by: .byTruncatingTail)

			guard let identifier = guid ?? link ?? date
			else {
				THLogError("can not obtain identifier for item:\(item)")
				return THLocalizedString("can not obtain item identifier")
			}

			let old_Idx = items.firstIndex(where: { $0.identifier == identifier || $0.isLikeItem(with: title, pubDate: pubDate) })
			let old_item = old_Idx != nil ? items[old_Idx!] : nil

			let received = old_item?.received ?? nowDate

			let item = RssChannelItem(identifier: identifier, received: received)

			item.published = old_item?.published ?? pubDate
			item.updated = pubDate
			
			item.title = title
			item.link = link != nil ? URL(string: link!) : nil
			item.contentText = contentText

			item.thumbnail = mediaUrl != nil ? URL(string: mediaUrl!) : nil

			if let old_Idx = old_Idx, let old_item = old_item {
				items.remove(at: old_Idx)

				item.checkedDate = old_item.checkedDate
				item.pinndedDate = old_item.pinndedDate
				item.thumbnail = old_item.thumbnail
			}

			if item.thumbnail == nil {
				if let link = item.link {

					let a_finir = 1
					if 	link.absoluteString.contains("aljazeera.com") ||
						link.absoluteString.contains("lefigaro.fr") ||
						link.absoluteString.contains("theskatingtimes.com") ||
						link.absoluteString.contains("macg.co") ||
						link.absoluteString.contains("macrumors.com") ||
						link.absoluteString.contains("arstechnica") ||
						link.absoluteString.contains("valeursactuelles.com") ||
						link.absoluteString.contains("lopinion.fr") ||
						link.absoluteString.contains("goldenskate.com") ||
						link.absoluteString.contains("generation-trail.com") {
						item.articleImage = RssArticleImage(link: link)
						item.articleImage!.start( {(ok: Bool, error: String?) in
							if ok == false {
								THLogError("link:\(link.absoluteString)")
								return
							}
							item.thumbnail = item.articleImage?.extractedImage
						})
					}
				}
			}

//			if let dupItem = items.firstIndex(where: { $0.isLike(item) }) {
//				THLogError("found like duplicated item. dupItem:\(items[dupItem]) item:\(item)")
//				items.remove(at: dupItem)
//			}

//			if onCreation == true {
//				item.checked = true
//			}

			items.append(item)
			items.sort(by: { ($0.published ?? $0.received) >  ($1.published ?? $1.received) })
		}

		let max = 500

		if p.items.count > Int(max / 3) {
			THLogError("received more than 100 items (\(p.items.count))")
		}
	
		// améliorer : limite par temps sur x jours ?
		if items.count > max {
			items.removeLast(items.count - max)
		}
	
		// on error si on à recu des items aucun conservés
		if p.items.count > 0 && items.count == 0 {
			return THLocalizedString("can not parse received items")
		}

		return nil
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
