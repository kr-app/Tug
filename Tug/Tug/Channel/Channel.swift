//  Channel.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class Channel: THDistantObject, THDictionarySerializationProtocol {
	var creationDate: Date!
	var identifier: String!
	var onCreation = false

	var url: URL?

	var disabled = false
	var title: String?
	var link: URL?
	var poster: URL?

	var items = [ChannelItem]()

	private var synchronizeTimer: Timer?

	// MARK: -

	override init() {
		super.init()
	}

	// MARK: -

	func displayTitle() -> String {
		return self.title ?? self.link?.th_reducedHost ?? self.url?.th_reducedHost ?? "nil"
	}

	func displayName() -> String {
		THFatalError("not implemented")
	}

	func hasUnreaded() -> Bool {
		THFatalError("not implemented")
	}

	// MARK: -

	func dictionaryRepresentation() -> THDictionaryRepresentation {

		let coder = THDictionaryRepresentation()

		coder.setDate(creationDate, forKey: "creationDate")

		coder.setUrl(url, forKey: "url")
		coder.setDate(lastUpdate, forKey: "lastUpdate")
		coder.setDate(lastError?.date, forKey: "lastError-date")
		coder.setString(lastError?.error, forKey: "lastError-error")

		coder.setBool(disabled, forKey: "disabled")
		coder.setString(title, forKey: "title")
		coder.setUrl(link, forKey: "link")
		coder.setUrl(poster, forKey: "poster")

		coder.setObjects(items, forKey: "items")

		return coder
	}

	required init(withDictionaryRepresentation dictionaryRepresentation: THDictionaryRepresentation) {
		super.init()

		creationDate = dictionaryRepresentation.date(forKey: "creationDate")
		if creationDate == nil {
			creationDate = dictionaryRepresentation.date(forKey: "createdDate") ?? Date()
		}

		url = dictionaryRepresentation.url(forKey: "url")
		lastUpdate = dictionaryRepresentation.date(forKey: "lastUpdate")
		if let lastErrorDate = dictionaryRepresentation.date(forKey: "lastError-date"), let lastErrorError = dictionaryRepresentation.string(forKey: "lastError-error") {
			lastError = (date: lastErrorDate, error: lastErrorError)
		}

		disabled = dictionaryRepresentation.bool(forKey: "disabled") ?? false
		title = dictionaryRepresentation.string(forKey: "title")
		link = dictionaryRepresentation.url(forKey: "link") ?? dictionaryRepresentation.url(forKey: "webLink")
		poster = dictionaryRepresentation.url(forKey:  "poster")
	}

	// MARK: -

	func contains(stringValue: String) -> Bool {
		for s in [self.title, self.url?.absoluteString, self.link?.absoluteString] {
			if s?.th_containsLike(stringValue) == true {
				return true
			}
		}
		return false
	}

	// MARK: -

	func getFilename(withExt ext: String) -> String {
		return "\(identifier)".th_appendingPathExtension(ext)
	}

	func getFileUrl(dirPath: String) -> URL {
		let path = dirPath.th_appendingPathComponent(getFilename(withExt: "plist"))
		return URL(fileURLWithPath: path)
	}

	func save(toDir dirPath: String) -> Bool {
		let path = dirPath.th_appendingPathComponent(getFilename(withExt: "plist"))
		THLogDebug("path:\(path.th_abbreviatingWithTildeInPath)")

		if dictionaryRepresentation().write(toFile: path) == false {
			THLogError("write == false path:\(path)")
			return false
		}

		var w = "title: \(title)"
		w += "\nurl: \(url?.absoluteString)"
		w += "\nlink: \(link?.absoluteString)"

		if THFinderMdItem.setMdItemWhereFroms([w], atPath: path) == false {
			THLogError("setMdItemWhereFroms == false path:\(path)")
		}

		return true
	}

	func trashFile(fromDir dirPath: String) -> Bool {
		let path = dirPath.th_appendingPathComponent(getFilename(withExt: "plist"))

		if FileManager.default.fileExists(atPath: path) == true {
			if FileManager.default.th_traskItem(at: URL(fileURLWithPath: path)) == false {
				THLogError("th_traskItem == false path:\(path)")
				return false
			}
		}

		return true
	}

	func synchronise(dirPath: String, immediately: Bool = false) {
		synchronizeTimer?.invalidate()

		if immediately == true {
			if self.save(toDir: dirPath) == false {
				THLogError("save == false")
			}
			return
		}

		synchronizeTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: {(timer: Timer) in
			if self.save(toDir: dirPath) == false {
				THLogError("save == false")
			}
		})
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
