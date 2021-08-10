// UserPreferences.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class UserPreferences: NSObject {
	static let shared = UserPreferences()

	var refreshInterval: Int?
	var actionOnItemClick: String?
	var previewHighlightMode: Int?

	override init() {
		super.init()
		self.loadFromUserDefaults()
	}
	
	private func loadFromUserDefaults() {
		let ud = UserDefaults.standard

		refreshInterval = ud.integer(forKey: "refreshInterval")
		actionOnItemClick = ud.object(forKey: "actionOnItemClick") as? String
		previewHighlightMode = ud.integer(forKey: "previewHighlightMode")
	}

	func synchronize() {
		let ud = UserDefaults.standard

		ud.set((refreshInterval != nil && refreshInterval! > 0) ? refreshInterval! : nil, forKey: "refreshInterval")
		ud.set(actionOnItemClick, forKey: "actionOnItemClick")
		ud.set(previewHighlightMode, forKey: "previewHighlightMode")
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
