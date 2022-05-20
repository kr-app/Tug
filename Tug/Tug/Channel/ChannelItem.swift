//  ChannelItem.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class ChannelItem: NSObject, THDictionarySerializationProtocol {

	var identifier: String
	var received: Date

	var published: Date?
	var updated: Date?

	var title: String?
	var link: URL?
	var contentText: String?
	var thumbnail: URL?
	var views: Int?
	var category: String?

	var checkedDate: Date?
	var pinndedDate: Date?
	var ruleExcluded = false
	var userDeleted = false

	var checked: Bool { get { return checkedDate != nil } }
	var pinned: Bool { get { return pinndedDate != nil } }

	override var description: String {
		var d = "identifier: \(identifier) received: \(received) published: \(published)"
		if let updated = updated {
			 d += " updated:\(updated)"
		}
		return th_description(d + " title: \(title)")
	}

	init(identifier: String, received: Date) {
		self.identifier = identifier
		self.received = received
	}

	func dictionaryRepresentation() -> THDictionaryRepresentation {
		let coder = THDictionaryRepresentation()

		coder.setString(identifier, forKey: "identifier")
		coder.setDate(received, forKey: "received")

		coder.setDate(published, forKey: "published")
		coder.setDate(updated, forKey: "updated")

		coder.setString(title, forKey: "title")
		coder.setUrl(link, forKey: "link")
		coder.setString(contentText, forKey: "contentText")
		coder.setUrl(thumbnail, forKey: "thumbnail")
		coder.setInt(views, forKey: "views")
		coder.setString(category, forKey: "category")

		coder.setDate(checkedDate, forKey: "checkedDate")
		coder.setDate(pinndedDate, forKey: "pinndedDate")
		coder.setBool(ruleExcluded == true ? true : nil, forKey: "ruleExcluded")
		coder.setBool(userDeleted == true ? true : nil, forKey: "userDeleted")

		return coder
	}

	required init(withDictionaryRepresentation dictionaryRepresentation: THDictionaryRepresentation) {
		identifier = dictionaryRepresentation.string(forKey: "identifier")!
		received = dictionaryRepresentation.date(forKey: "received")!

		published = dictionaryRepresentation.date(forKey: "published")
		updated = dictionaryRepresentation.date(forKey: "updated")

		title = dictionaryRepresentation.string(forKey: "title")
		link = dictionaryRepresentation.url(forKey: "link")
		contentText = dictionaryRepresentation.string(forKey: "contentText") ?? dictionaryRepresentation.string(forKey: "content")
		thumbnail = dictionaryRepresentation.url(forKey: "thumbnail")
		views = dictionaryRepresentation.int(forKey: "views")
		category = dictionaryRepresentation.string(forKey: "category")

		checkedDate = dictionaryRepresentation.date(forKey: "checkedDate")
		pinndedDate = dictionaryRepresentation.date(forKey: "pinndedDate")
		ruleExcluded = dictionaryRepresentation.bool(forKey: "ruleExcluded") ?? false
		userDeleted = dictionaryRepresentation.bool(forKey: "userDeleted") ?? false

		if checkedDate == nil && dictionaryRepresentation.bool(forKey: "checked") == true {
			checkedDate = received
		}
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
extension ChannelItem {

	func isRecent(refDate: TimeInterval) -> Bool {
		if self.received.timeIntervalSinceReferenceDate >= refDate {
			return true
		}
		return false
	}

	func isLikeItem(with title: String?, pubDate: Date?) -> Bool {
		if let title = title, let pubDate = pubDate {
			return self.title == title && self.published == pubDate
		}
		return false
	}

	func contains(stringValue: String) -> Bool {
		for s in [self.title, self.contentText, self.link?.absoluteString, self.category] {
			if s?.th_containsLike(stringValue) == true {
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


//--------------------------------------------------------------------------------------------------------------------------------------------
extension ChannelItem {

	func sorted(compared to: ChannelItem) -> Bool {
		let rcv0 = self.received
		let rcv1 = to.received

		if rcv0 == rcv1 {
			if let up0 = self.published, let up1 = to.published {
				return up0 > up1
			}
		}

		return rcv0 > rcv1
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
