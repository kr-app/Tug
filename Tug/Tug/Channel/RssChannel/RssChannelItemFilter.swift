// RssChannelFilter.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
enum RssChannelFilterStringMode: Int {
	case begin = 1
	case contains = 2
	case containsArray = 3
}

class RssChannelFilterString: NSObject, THDictionarySerializationProtocol {
	let mode: RssChannelFilterStringMode
	var value: Any?
	var stringValue: String { get { value as! String } }
	
	init(mode: RssChannelFilterStringMode, value: Any) {
		self.mode = mode
		self.value = value
	}
	
	override var description: String {
		th_description("mode:\(mode) value:\(value)")
	}

	func dictionaryRepresentation() -> THDictionaryRepresentation {
		let coder = THDictionaryRepresentation()
		coder.setInt(mode.rawValue, forKey: "mode")
		coder.setAnyValue(value, forKey: "value")
		return coder
	}

	required init(withDictionaryRepresentation dictionaryRepresentation: THDictionaryRepresentation) {
		mode = RssChannelFilterStringMode(rawValue: dictionaryRepresentation.int(forKey: "mode")!)!
		value = dictionaryRepresentation.anyValue(forKey: "value") ?? dictionaryRepresentation.string(forKey: "string")!
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
enum RssChannelFilterKind: Int {
	case exclude = 1
}

class RssChannelFilter: NSObject, THDictionarySerializationProtocol {
	var kind: RssChannelFilterKind = .exclude
	let host: String?
	let titleFilter: RssChannelFilterString

	init(host: String? = nil, titleFilter: RssChannelFilterString) {
		self.host = host
		self.titleFilter = titleFilter
	}
	
	override var description: String {
		th_description("kind:\(kind) host:\(host) titleFilter:\(titleFilter)")
	}

	func match(withHost channelHost: String, itemTitle: String) -> Bool {

		if let host = self.host {
			if channelHost.contains(host) == false {
				return false
			}
		}

		if titleFilter.mode == .begin {
			if itemTitle.th_hasPrefixInsensitive(titleFilter.stringValue) {
				return true
			}
		}
		else if titleFilter.mode == .contains {
			if itemTitle.th_isLike(titleFilter.stringValue) {
				return true
			}
		}
		else if titleFilter.mode == .containsArray {
			let strings = titleFilter.value as! [String]
			for string in strings {
				if itemTitle.th_isLike(string) == false {
					return false
				}
			}
			return strings.count > 0
		}

		return false
	}
	
	func dictionaryRepresentation() -> THDictionaryRepresentation {
		let coder = THDictionaryRepresentation()
		coder.setInt(kind.rawValue, forKey: "kind")
		coder.setString(host, forKey: "host")
		coder.setObject(titleFilter, forKey: "titleFilter")
		return coder
	}

	required init(withDictionaryRepresentation dictionaryRepresentation: THDictionaryRepresentation) {
		kind = RssChannelFilterKind(rawValue: dictionaryRepresentation.int(forKey: "kind")!)!
		host = dictionaryRepresentation.string(forKey: "host")
		titleFilter = RssChannelFilterString.th_object(fromDictionaryRepresentation: dictionaryRepresentation, forKey: "titleFilter") ?? RssChannelFilterString.th_object(fromDictionaryRepresentation: dictionaryRepresentation, forKey: "title")!
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
class RssChannelFilterManager {
	static let shared = RssChannelFilterManager(filePath: FileManager.th_documentsPath().th_appendingPathComponent("RssChannelFilterManager.plist"))

	private(set) var filters = [RssChannelFilter]()
	private let filePath: String
	private var fileStamps: Date?

	init(filePath: String) {
		self.filePath = filePath
		
		if let filters = filters(fromFile: filePath) {
			self.filters = filters
			self.fileStamps = FileManager.th_modDate1970(atPath: filePath)
		}
	}
	
	func synchronize() {
		if FileManager.default.fileExists(atPath: filePath) == false {
			return
		}
		
		let modDate = FileManager.th_modDate1970(atPath: filePath)
		if modDate != nil && modDate == fileStamps {
			return
		}

		self.filters = filters(fromFile: filePath) ?? []
		self.fileStamps = modDate
	}
	
	private func filters(fromFile file: String) -> [RssChannelFilter]? {
		if FileManager.default.fileExists(atPath: file) == false {
			return nil
		}

		guard let rep = THDictionaryRepresentation(contentsOfFile: file)
		else {
			THLogError("rep == nil file:\(file)")
			return nil
		}

		guard let filters = RssChannelFilter.th_objects(fromDictionaryRepresentation: rep, forKey: "filters")
		else {
			THLogError("filters == nil file:\(file)")
			return nil
		}
		
		for filter in filters {
			THLogInfo("filter:\(filter)")
		}

		return filters
	}
	
	private func save() -> Bool {
		let rep = THDictionaryRepresentation()
		rep.setObjects(filters, forKey: "filters")
		if rep.write(toFile: filePath) == false {
			THLogError("write == false filePath:\(filePath)")
			return false
		}
		return true
	}

	func addFilter(_ filter: RssChannelFilter) {
//		for f in filters {
//			if f.titleFilter.mode == .begin || f.titleFilter
//		}
//
//		if filters.contains(where: {$0.host == filter.host && $0.titleFilter.string == filter.titleFilter.string }) == true {
//			return
//		}
		
		filters.append(filter)
		
		if save() == false {
			THLogError("save == false")
		}
	}

	func excludedChannel(_ channel: RssChannel, byTitle title: String) -> Bool {
		let url = channel.url!.absoluteString
		return filters.contains(where: { $0.match(withHost: url, itemTitle: title) == true })
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
