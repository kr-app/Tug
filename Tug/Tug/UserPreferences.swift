// UserPreferences.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class UserPreferences: NSObject {
	static let shared = UserPreferences()

	var refreshInterval: TimeInterval = 0.0
	var actionOnItemClick: String?
	var previewHighlightMode: Int?

	override init() {
		super.init()
		self.loadFromUserDefaults()
	}
	
	private func loadFromUserDefaults() {
		refreshInterval = TimeInterval(UserDefaults.standard.integer(forKey: "refreshInterval"))
		actionOnItemClick = UserDefaults.standard.object(forKey: "actionOnItemClick") as? String
		previewHighlightMode = UserDefaults.standard.integer(forKey: "previewHighlightMode")
	}

	func synchronize() {
		UserDefaults.standard.set(refreshInterval > 0.0 ? Int(refreshInterval.rounded(.down)) : nil, forKey: "refreshInterval")
		UserDefaults.standard.set(actionOnItemClick, forKey: "actionOnItemClick")
		UserDefaults.standard.set(previewHighlightMode, forKey: "previewHighlightMode")
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
