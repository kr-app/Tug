// RssChannel.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class RssChannel: Channel {

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
		if let title = self.title {
			if title.isEmpty == false && title.hasPrefix("{") == false && title.hasSuffix("}") == false {
				return title
			}
		}
		return link?.th_reducedHost ?? url?.th_reducedHost ?? "nil"
	}

	// MARK: -
	
	override func updateRequest() -> URLRequest {
		URLRequest(url: self.url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15.0)
	}

	override func shouldUpdate() -> Bool {
		guard let lu = lastUpdate
		else {
			return true
		}

		let luNow = lu.timeIntervalSinceNow

		if lastError != nil {
			return luNow <= -5.th_min
		}

		// moins de 5 min -> false
		if luNow > -5.th_min {
			return false
		}

		let refreshInterval = /*UserPreferences.shared.refreshInterval > 0 ? UserPreferences.shared.refreshInterval : */15.0.th_min
		return luNow <= refreshInterval
	}
		
	override func parse(data: Data) -> String? {

#if DEBUG
		data.writeDebugOutput(to: FileManager.th_appCachesDir("RssChannel").th_appendingPathComponent("\(identifier).xml"))
#endif

		let p = THRSSFeedParser(data: data, sourceInfo: url)
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

			let title = ChannelDataTransformer.transform(title: item.value(named: "title")?.content)
			let link = item.value(named: "link")?.content
			var contentText = item.value(named: "description")?.content

			let guid = linkAsId ? nil : item.value(named: "guid")?.content
//			let guidPermaLink = item.value(named: "guid")?.attributes?["isPermaLink"] as? String

			var mediaUrl = MediaUrlExtractor.urlFromMediaContent(item: item) ?? MediaUrlExtractor.urlFromEnclosure(item: item)
			let date = item.value(named: "pubDate")?.content

			let pubDate = date != nil ? pubDateConvertor.pubDate(from: date!) : nil

			if mediaUrl == nil {
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

			let category = item.value(named: "category")?.content

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

			contentText = RssChannelDataTransformer.transform(contentText: contentText)

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
			item.category = category

			if let old_Idx = old_Idx, let old_item = old_item {
				items.remove(at: old_Idx)

				item.checkedDate = old_item.checkedDate
				item.pinndedDate = old_item.pinndedDate
				item.thumbnail = old_item.thumbnail
				item.commentCount = old_item.commentCount
			}

//			if item.thumbnail == nil {
				if let link = item.link {
					if RssWebItemAttrs.canStart(for: link) {
//						let pageItem = RssWebItemAttrs.item(for: link)
	//					if pageItem == nil {
							let pageItem = RssWebItemAttrs(link: link)

							pageItem.start( {(attrs: [String: Any]?, error: String?) in
								guard let attrs = attrs
								else {
									THLogError("item:\(item), link:\(link.absoluteString), error:\(error)")
									return
								}
								if let thumbnail = attrs[RssWebItemAttrKey.ogImage.rawValue] as? URL {
									item.thumbnail = thumbnail
								}
								if let commentCount = attrs[RssWebItemAttrKey.commentCount.rawValue] as? Int {
									item.commentCount = commentCount
								}
							})
//						}
//						else if let thumbnail = pageItem?.extractedImage {
//							item.thumbnail = thumbnail
//						}
					}
				}
	//		}

			if let title = item.title {
				if RssChannelFilterManager.shared.isExcludedItem(itemTitle: title, channel: self) {
					item.ruleExcluded = true
				}
			}

			items.append(item)
			items.sort(by: { ($0.published ?? $0.received) >  ($1.published ?? $1.received) })
		}

		let max = 5000

		if p.items.count > Int(max / 3) {
			THLogError("received more than 100 items (\(p.items.count))")
		}
	
		// am??liorer : limite par temps sur x jours ?
		if items.count > max {
			items.removeLast(items.count - max)
		}
	
		// on error si on ?? recu des items aucun conserv??s
		if p.items.count > 0 && items.count == 0 {
			return THLocalizedString("can not parse received items")
		}

		return nil
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
