//  ChannelItem.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class ChannelItem: NSObject, THDictionarySerializationProtocol {

	var identifier: String!
	var received: Date!

	var published: Date?
	var updated: Date?

	var title: String?
	var link: URL?
	var content: String?
	var thumbnail: URL?
	var views: Int?

	var checkedDate: Date?
	var pinndedDate: Date?

	var wallDate: Date { get { return received }}
	var checked: Bool { get { return checkedDate != nil } }
	var pinned: Bool { get { return pinndedDate != nil } }

	override var description: String {
		th_description("identifier: \(identifier) published: \(published) updated:\(updated) title: \(title?.th_truncate(maxChars: 20, by: .byTruncatingTail))")
	}

	override init() {
	}

	func dictionaryRepresentation() -> THDictionaryRepresentation {
		let coder = THDictionaryRepresentation()

		coder.setString(identifier!, forKey: "identifier")
		coder.setDate(received!, forKey: "received")

		coder.setDate(published, forKey: "published")
		coder.setDate(updated, forKey: "updated")

		coder.setString(title, forKey: "title")
		coder.setUrl(link, forKey: "link")
		coder.setString(content, forKey: "content")
		coder.setUrl(thumbnail, forKey: "thumbnail")
		coder.setInt(views, forKey: "views")

		coder.setDate(checkedDate, forKey: "checkedDate")
		coder.setDate(pinndedDate, forKey: "pinndedDate")

		return coder
	}

	required init(withDictionaryRepresentation dictionaryRepresentation: THDictionaryRepresentation) {
		identifier = dictionaryRepresentation.string(forKey: "identifier")!
		received = dictionaryRepresentation.date(forKey: "received")!

		published = dictionaryRepresentation.date(forKey: "published")
		updated = dictionaryRepresentation.date(forKey: "updated")

		title = dictionaryRepresentation.string(forKey: "title")
		link = dictionaryRepresentation.url(forKey: "link")
		content = dictionaryRepresentation.string(forKey: "content")
		thumbnail = dictionaryRepresentation.url(forKey: "thumbnail")
		views = dictionaryRepresentation.int(forKey: "views")

		checkedDate = dictionaryRepresentation.date(forKey: "checkedDate")
		pinndedDate = dictionaryRepresentation.date(forKey: "pinndedDate")

		if checkedDate == nil && dictionaryRepresentation.bool(forKey: "checked") == true {
			checkedDate = received ?? Date()
		}
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
extension ChannelItem {

	func isRecent(refDate: TimeInterval) -> Bool {
		if self.wallDate.timeIntervalSinceReferenceDate >= refDate {
			return true
		}
		return false
	}

	func isLike(_ item: ChannelItem) -> Bool {
		guard let title = self.title, let itemTitle = item.title
		else {
			return false
		}
		if title != itemTitle {
			return false
		}

		if let link = self.link, let itemLink = item.link {
			if link != itemLink {
				return false
			}
		}

		// le contenu (content) peut varié, être tronqué, etc.

		return true
	}

	func contains(stringValue: String) -> Bool {
		for s in [self.title, self.content, self.link?.absoluteString] {
			if s != nil && s!.range(of: stringValue, options: .caseInsensitive) != nil {
				return true
			}
		}
		return false
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
extension ChannelItem {

	func displayViews() -> String? {
		guard let v = views
		else {
			return nil
		}

		if v > 1000 * 1000 {
			return (Double(v / (1000 * 1000)).rounded()).th_string(2) + "M views"
		}
		if v > 1000 {
			return (Double(v / (1000)).rounded()).th_string(1) + "K views"
		}
		if v > 1 {
			return String(v) + " views"
		}

		return v == 1 ? "1 view" : "0 view"
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
