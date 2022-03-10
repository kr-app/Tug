//  Channel.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class Channel: THDistantObject, THDictionarySerializationProtocol {
	var creationDate: Date!
	var identifier: String!
	var onCreation = false

	var url: URL?
	var link: URL?

	var disabled = false
	var title: String?
	var webLink: URL?
	var poster: URL?

	var items = [ChannelItem]()

	private var synchronizeTimer: Timer?

	// MARK: -

	override init() {
		super.init()
	}

	// MARK: -

	func dictionaryRepresentation() -> THDictionaryRepresentation {

		let coder = THDictionaryRepresentation()

		coder.setDate(creationDate, forKey: "creationDate")

		coder.setUrl(url, forKey: "url")
		coder.setUrl(link, forKey: "link")
		coder.setDate(lastUpdate, forKey: "lastUpdate")
		coder.setString(lastError, forKey: "lastError")

		coder.setBool(disabled, forKey: "disabled")
		coder.setString(title, forKey: "title")
		coder.setUrl(webLink, forKey: "webLink")
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
		link = dictionaryRepresentation.url(forKey: "link")
		lastUpdate = dictionaryRepresentation.date(forKey: "lastUpdate")
		lastError = dictionaryRepresentation.string(forKey: "lastError")

		disabled = dictionaryRepresentation.bool(forKey: "disabled") ?? false
		title = dictionaryRepresentation.string(forKey: "title")
		webLink = dictionaryRepresentation.url(forKey: "webLink") ?? dictionaryRepresentation.url(forKey: "link")
		poster = dictionaryRepresentation.url(forKey:  "poster")
	}

	// MARK: -

	func getFilename(withExt ext: String) -> String {
		return "\(identifier)".th_appendingPathExtension(ext)
	}

	func save(toDir dirPath: String) -> Bool {
		let path = dirPath.th_appendingPathComponent(getFilename(withExt: "plist"))
		THLogDebug("path:\(path.th_abbreviatingWithTildeInPath())")

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

	func remove(fromDir dirPath: String) -> Bool {
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
