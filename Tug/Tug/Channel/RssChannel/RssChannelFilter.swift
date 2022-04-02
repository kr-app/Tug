// RssChannelFilter.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
enum RssChannelFilterAction: Int {
	case exclude = 1
}

enum RssChannelFilterTarget: Int {
	case title
}

enum RssChannelFilterMode: Int {
	case beginBy
	case containsLike
}

enum RssChannelFilterMask: Int {
	case all
	case any
}

struct RssChannelFilterVerbs {
	let action: RssChannelFilterAction
	let target: RssChannelFilterTarget
	let mode: RssChannelFilterMode
	let mask: RssChannelFilterMask?

	private static let actions: [RssChannelFilterAction: String] = [.exclude: "exclude"]
	private static let targets: [RssChannelFilterTarget: String] = [.title: "title"]
	private static let modes: [RssChannelFilterMode: String] = [.beginBy: "begin", .containsLike: "containsLike"]
	private static let marks: [RssChannelFilterMask: String] = [.all: "all", .any: "any"]

	init?(fromStringRepresentation stringRepresentation: String?) {
		guard let comps = stringRepresentation?.components(separatedBy: " ")
		else {
			return nil
		}

		self.action = Self.actions.first(where: {$1 == comps[0] })!.key
		self.target = Self.targets.first(where: {$1 == comps[1] })!.key
		self.mode = Self.modes.first(where: {$1 == comps[2] })!.key
		self.mask = comps.count == 4 ? Self.marks.first(where: {$1 == comps[3] })!.key : nil
	}

	func stringRepresentation() -> String {
		var rep = Self.actions[action]! + " " + Self.targets[target]! + " " + Self.modes[mode]!
		if let mask = mask {
			rep += " " + Self.marks[mask]!
		}
		return rep
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
class RssChannelFilter: NSObject, THDictionarySerializationProtocol {
	let hosts: [String]?
	let verbs: RssChannelFilterVerbs
	let value: Any

	init(hosts: [String]? = nil, verbs: RssChannelFilterVerbs, value: Any) {
		self.hosts = hosts
		self.verbs = verbs
		self.value = value
	}
	
	override var description: String {
		th_description("hosts:\(hosts) verbs:\(verbs.stringRepresentation()) value:\(value)")
	}

	func excluded(channelUrl: String, itemTitle: String) -> Bool {

		if let hosts = self.hosts {
			if hosts.contains(where: { channelUrl.contains($0) }) == false {
				return false
			}
		}

		if verbs.target == .title {
			if verbs.mode == .beginBy {
				if let values = value as? [String] {
					if values.contains(where: { itemTitle.th_hasPrefixInsensitive($0) }) {
						return true
					}
				}
				else if let value = self.value as? String {
					if itemTitle.th_hasPrefixInsensitive(value) {
						return true
					}
				}
			}
			else if verbs.mode == .containsLike {
				if let values = value as? [String] {
					if verbs.mask == .any {
						if values.contains(where: { itemTitle.th_containsLike($0) }) {
							return true
						}
					}
					else {
						if !values.contains(where: { !itemTitle.th_containsLike($0) }) {
							return true
						}
					}
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

		coder.setString(hosts?.joined(separator: " "), forKey: "hosts")
		coder.setString(verbs.stringRepresentation(), forKey: "verbs")
		coder.setAnyValue(value, forKey: "value")

		return coder
	}

	required init(withDictionaryRepresentation dictionaryRepresentation: THDictionaryRepresentation) {
		self.hosts = (dictionaryRepresentation.string(forKey: "hosts") ?? dictionaryRepresentation.string(forKey: "host"))?.components(separatedBy: " ")
		self.verbs = RssChannelFilterVerbs(fromStringRepresentation: dictionaryRepresentation.string(forKey: "verbs")!)!
		self.value = dictionaryRepresentation.anyValue(forKey: "value")!

		if verbs.mode == .containsLike && verbs.mask == nil && value is [String] {
			THFatalError("invalid mask for hosts:\(hosts), verbs:\(verbs), value:\(value)")
		}
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
			THLogDebug("filter \(idx) host:\(filter.hosts) verbs:\(filter.verbs.stringRepresentation()) value:\(filter.value)")
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
