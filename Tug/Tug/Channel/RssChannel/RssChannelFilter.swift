// RssChannelFilter.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
enum RssChannelFilterAction: Int {
	case exclude = 1
}

enum RssChannelFilterTarget: Int {
	case title = 1
}

enum RssChannelFilterMode: Int {
	case beginBy = 1
	case containsLike = 2
}

struct RssChannelFilterVerbs {
	let action: RssChannelFilterAction
	let target: RssChannelFilterTarget
	let mode: RssChannelFilterMode

	private static let actions: [RssChannelFilterAction: String] = [.exclude: "exclude"]
	private static let targets: [RssChannelFilterTarget: String] = [.title: "title"]
	private static let modes: [RssChannelFilterMode: String] = [.beginBy: "begin", .containsLike: "containsLike"]

	init?(fromStringRepresentation stringRepresentation: String?) {
		guard let comps = stringRepresentation?.components(separatedBy: " "), comps.count == 3
		else {
			return nil
		}

		self.action = Self.actions.first(where: {$1 == comps[0] })!.key
		self.target = Self.targets.first(where: {$1 == comps[1] })!.key
		self.mode = Self.modes.first(where: {$1 == comps[2] })!.key
	}

	func stringRepresentation() -> String {
		return Self.actions[action]! + " " + Self.targets[target]! + " " + Self.modes[mode]!
	}
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
class RssChannelFilter: NSObject, THDictionarySerializationProtocol {
	let host: String?
	let verbs: RssChannelFilterVerbs
	let value: Any

	init(host: String? = nil, verbs: RssChannelFilterVerbs, value: Any) {
		self.host = host
		self.verbs = verbs
		self.value = value
	}
	
	override var description: String {
		th_description("host:\(host) verbs:\(verbs.stringRepresentation()) value:\(value)")
	}

	func excluded(channelUrl: String, itemTitle: String) -> Bool {

		if let host = self.host {
			if channelUrl.contains(host) == false {
				return false
			}
		}

		if verbs.target == .title {
			if verbs.mode == .beginBy {
				if itemTitle.th_hasPrefixInsensitive(value as! String) {
					return true
				}
			}
			else if verbs.mode == .containsLike {
				if let values = value as? [String] {
					for string in values {
						if itemTitle.th_containsLike(string) == false {
							return false
						}
					}
					return true
				}
				else if let value = self.value as? String {
					if itemTitle.th_containsLike(value) {
						return true
					}
				}
			}
		}

		return false
	}
	
	func dictionaryRepresentation() -> THDictionaryRepresentation {
		let coder = THDictionaryRepresentation()

		coder.setString(host, forKey: "host")
		coder.setString(verbs.stringRepresentation(), forKey: "verbs")
		coder.setAnyValue(value, forKey: "value")

		return coder
	}

	required init(withDictionaryRepresentation dictionaryRepresentation: THDictionaryRepresentation) {
		self.host = dictionaryRepresentation.string(forKey: "host")
		self.verbs = RssChannelFilterVerbs(fromStringRepresentation: dictionaryRepresentation.string(forKey: "verbs")!)!
		self.value = dictionaryRepresentation.anyValue(forKey: "value")!
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

	func printToConsole() {
		THLogDebug("filters:\(filters.count)")

		for (idx, filter) in filters.enumerated() {
			THLogDebug("filter \(idx) host:\(filter.host) verbs:\(filter.verbs.stringRepresentation()) value:\(filter.value)")
		}
	}

	func synchronizeFromDisk() {
		if FileManager.default.fileExists(atPath: filePath) == false {
			return
		}
		
		let modDate = FileManager.th_modDate1970(atPath: filePath)
		if modDate != nil && modDate == fileStamps {
			return
		}

		self.filters = filters(fromFile: filePath) ?? []
		self.fileStamps = modDate

		printToConsole()
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

		return filters
	}
	
	func synchronizeToDisk() -> Bool {
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
		
		if synchronizeToDisk() == false {
			THLogError("synchronizeToDisk == false")
		}
	}

	func isExcludedItem(itemTitle: String, channel: RssChannel) -> Bool {
		let url = channel.url!.absoluteString
		return filters.contains(where: { $0.excluded(channelUrl: url , itemTitle: itemTitle) == true })
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
