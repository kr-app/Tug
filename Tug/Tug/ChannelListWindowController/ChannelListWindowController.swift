// ChannelListWindowController.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class ChannelListFooter: NSView {
	override func draw(_ dirtyRect: NSRect) {

		NSColor(calibratedWhite: 0.86, alpha: 1.0).set()
		NSBezierPath.fill(self.bounds)

		NSColor(calibratedWhite: 0.99, alpha: 1.0).set()
		NSBezierPath.fill(NSRect(1.0, 1.0, self.bounds.size.width - 2.0, self.bounds.size.height - 2.0))
	}
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
class ChannelCellView: NSTableCellView {

	var onError = false

	override var backgroundStyle: NSView.BackgroundStyle { didSet {
		applyCurrentColors(backgroundStyle)
	}}

	private func applyCurrentColors(_ style: NSView.BackgroundStyle) {
		textField?.textColor = onError ? .red : style == .emphasized ? .white : .textColor
	}
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
fileprivate struct ObjectItem {
	let kind: Int
	let title: String?
	let channel: Channel?

	init(kind: Int, title: String? = nil, channel: Channel? = nil) {
		self.kind = kind
		self.title = title
		self.channel = channel
	}
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
class ChannelListWindowController : NSWindowController, NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate {

	static let shared = ChannelListWindowController(windowNibName: "ChannelListWindowController")

	@IBOutlet var tableView: NSTableView!

	@IBOutlet var c_onOff: NSSwitch!
	@IBOutlet var c_icon: NSImageView!
	@IBOutlet var c_titleLabel: NSTextField!
	@IBOutlet var c_urlField: NSTextField!
	@IBOutlet var c_lastUpdateLabel: NSTextField!
	@IBOutlet var c_lastErrorLabel: NSTextField!

	@IBOutlet var ytDetailsViewController: YtChannelDetailsViewController!
	@IBOutlet var noSelectionView: NSView!

	@IBOutlet var plusButton: THNSButtonBlock!
	@IBOutlet var minusButton: THNSButtonBlock!
	
	private let todayDf = THTodayDateFormatter(todayFormat: "HMS", otherFormatter: DateFormatter(dateStyle: .medium, timeStyle: .medium))
	private var objectList: [ObjectItem]?
	private var channelOnCreation: Channel?
	
	// MARK: -
	
	override func windowDidLoad() {
		super.windowDidLoad()
	
		self.window!.title = THLocalizedString("Channel List")

		tableView.menu = NSMenu(title: "menu", delegate: self, autoenablesItems: false)

		plusButton.actionBlock = {() in
			self.channelOnCreation = RssChannel()
			self.updateUI()

			self.tableView.selectRowIndexes(IndexSet(integer: self.objectList!.count - 1), byExtendingSelection: false)
			self.tableView.scrollRowToVisible(self.objectList!.count - 1)
		}

		minusButton.actionBlock = {() in
			let row = self.tableView.selectedRow

			if let object = row == -1 ? nil : self.objectList![row] {
				self.removeObject(object)
			}
		}

		updateUI()
	}
	
	override func showWindow(_ sender: Any?) {
		if self.isWindowLoaded == true {
			updateUI()
		}
		super.showWindow(sender)
	}
	
	// MARK: -
	
	private func updateUI() {
		updateUIObjectList()
		updateUISelection()
	}
	
	private func updateUIObjectList() {
		var objectList = [ObjectItem]()

		objectList.append(ObjectItem(kind: 10, title: THLocalizedString("News Rss")))
		for channel in RssChannelManager.shared.channels.sorted(by: { $0.displayName() < $1.displayName() }) {
			objectList.append(ObjectItem(kind: 1, channel: channel))
		}

		objectList.append(ObjectItem(kind: 10, title: THLocalizedString("YouTube")))
		for channel in YtChannelManager.shared.channels.sorted(by: { $0.displayName() < $1.displayName() }) {
			objectList.append(ObjectItem(kind: 2, channel: channel))
		}

		if let channel = channelOnCreation {
			objectList.append(ObjectItem(kind: 3, channel: channel))
		}

		self.objectList = objectList
		tableView.reloadData()
	}

	private func updateUISelection() {
		let row = self.tableView.selectedRow

		minusButton.isEnabled = row != -1
		noSelectionView.isHidden = row != -1

		let object = row == -1 ? nil : objectList![row]

		let detailsView = object?.kind == 1 ? c_titleLabel.superview! : object?.kind == 2 ? ytDetailsViewController.view : nil
		let detailsContainerView = noSelectionView.superview!

		detailsContainerView.subviews.forEach( {
			if ($0 is NSTextField) == false {
				$0.removeFromSuperview()
			}
		})

		if let detailsView = detailsView {
			detailsView.frame.size = detailsContainerView.frame.size
			detailsContainerView.addSubview(detailsView)
		}

		guard let object = object
		else {
			return
		}

		if object.kind == 1 {
			let channel = object.channel!

			c_icon.image = THWebIconLoader.shared.icon(forHost: channel.url?.host, startUpdate: true, allowsGeneric: true)
			c_titleLabel.objectValue = channel.title
			c_onOff.state = channel.disabled == true ? .off : .on

			c_urlField.objectValue = channel.url?.absoluteString

			let lu = channel.lastUpdate
			c_lastUpdateLabel.stringValue = lu != nil ? todayDf.string(from: lu!) : "--"

			c_lastErrorLabel.stringValue = channel.lastError ?? "--"
		}
		else if object.kind == 2 {
			ytDetailsViewController.updateUI(object.channel as! YtChannel)
		}
	}

	private func reloadSelectedRow() {
		let row = self.tableView.selectedRow
		if row == -1 {
			return
		}
		
		tableView.th_reloadData(forRowIndexes: IndexSet(integer: row))
	}

	private func removeObject(_ object: ObjectItem) {
		guard let channel = object.channel
		else {
			return
		}

		let title = THLocalizedString("Are you sure you want to delete \"") + channel.displayName() + "\""
		let msg = channel.link?.absoluteString ?? channel.url?.absoluteString
		let alert = NSAlert(withTitle: title, message: msg, buttons: [THLocalizedString("Delete"), THLocalizedString("Cancel")])

		alert.beginSheetModal(for: self.window!, completionHandler: {(response: NSApplication.ModalResponse) in
			if response == .alertFirstButtonReturn {
				DispatchQueue.main.async {
					ChannelManager.managerOfChannel(channel)?.removeChannel(channel.identifier)
					self.updateUI()
				}
			}
		})
	}
	
	// MARK: -
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return objectList?.count ?? 0
	}

	func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
		let item = objectList![row]
		return item.kind == 10
	}

	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return 24.0
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

		let object = objectList![row]

		if object.kind == 10 {
			let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "cell_group_id"), owner: self) as! NSTableCellView
			cell.textField?.objectValue = object.title
			return cell
		}

		let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "cell_id"), owner: self) as! ChannelCellView
		let channel = object.channel!

		var icon: NSImage?
		if object.kind == 1 {
			icon = THWebIconLoader.shared.icon(forHost: channel.url?.host, startUpdate: true, allowsGeneric: true)
		}
		else if object.kind == 2 {
			icon = THWebIconLoader.shared.icon(forHost: channel.link?.host, startUpdate: true, allowsGeneric: true)
		}

		cell.onError = channel.lastError != nil
		cell.textField?.stringValue = channel.displayName()
		cell.textField?.font = channel.hasUnreaded() ? NSFont.boldSystemFont(ofSize: NSFont.systemFontSize(for: .small)) : NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .small))
		cell.imageView?.image = channel.disabled ? icon?.th_imageGray() : icon

		return cell
	}

	func tableViewSelectionDidChange(_ notification: Notification) {
		updateUISelection()
	}

	func menuNeedsUpdate(_ menu: NSMenu) {
		menu.removeAllItems()

		let row = tableView.clickedRow
		let object = row == -1 ? nil : objectList![row]

		guard let object = object, let channel = object.channel
		else {
			return
		}

		menu.addItem(THMenuItem(title: THLocalizedString("Reveal in Finder"), block: {() in
			ChannelManager.managerOfChannel(channel)?.revealFile(channel: channel.identifier)
		}))

		menu.addItem(NSMenuItem.separator())

		menu.addItem(THMenuItem(title: THLocalizedString("Remove"), block: {() in
			self.removeObject(object)
		}))
	}

	@IBAction func tableViewAction(_ sender: NSTableView) {
		let row = self.tableView.selectedRow

		let object = row == -1 ? nil : objectList![row]
		let channel = object?.channel

		UserDefaults.standard.set(ChannelManager.managerOfChannel(channel)?.pathOfChannel(channel), forKey: "selected")
	}

	@IBAction func tableViewDoubleAction(_ sender: NSTableView) {
		let row = self.tableView.selectedRow

		let object = row == -1 ? nil : objectList![row]
		let channel = object?.channel

		guard let link = channel?.link
		else {
			return
		}

		DispatchQueue.main.async {
			if THFirefoxScriptingTools.createWindowIfNecessary() == false {
				THLogError("createWindowIfNecessary == false link:\(link)")
			}

			THOpenInBrowser.shared.open(url: link, completion: {(ok: Bool) in
				if ok == false {
					THLogError("open == false link:\(link)")
				}
			})
		}
	}

	// MARK: -

	@IBAction func onOffAction(_ sender: NSSwitch) {
		let row = self.tableView.selectedRow
		let disabled = sender.state == .off

		let object = row == -1 ? nil : objectList![row]
		guard let channel = object?.channel
		else {
			return
		}

		RssChannelManager.shared.setAttribute(disabled: disabled, channel: channel.identifier)
		reloadSelectedRow()

		if disabled == false {
			RssChannelManager.shared.updateChannel(channel.identifier, completion: {() in
				self.updateUISelection()
			})
		}
	}

	@IBAction func urlChangeAction(_ sender: NSTextField) {
		let row = self.tableView.selectedRow
		if row == -1 {
			return
		}

		let object = objectList![row]
		let kind = object.kind

		guard let channel = object.channel
		else {
			return
		}

		let url = c_urlField.stringValue.trimmingCharacters(in: .whitespaces)
	
		guard	url.isEmpty == false,
					let nUrl = URL(string: url),
					nUrl.host != nil
		else {
			return
		}
		
		if kind == 2 {
			RssChannelManager.shared.addChannel(url: nUrl, startUpdate: false)
			channelOnCreation = nil
			self.updateUI()

			RssChannelManager.shared.updateChannel(channel.identifier, completion: {() in
				self.updateUISelection()
			})
		
			return
		}

		RssChannelManager.shared.setAttribute(url: nUrl, channel: channel.identifier)
	
		RssChannelManager.shared.updateChannel(channel.identifier, completion: {() in
			self.updateUISelection()
		})
	}
	
	@IBAction func cleanAction(_ sender: NSButton) {
		let row = self.tableView.selectedRow
		if row == -1 {
			return
		}

		let object = objectList![row]
		guard let channel = object.channel
		else {
			return
		}

		RssChannelManager.shared.clean(channel: channel.identifier)
	
		RssChannelManager.shared.updateChannel(channel.identifier, completion: {() in
			self.updateUISelection()
		})
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
