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
class ChannelListWindowController : NSWindowController,
																NSTableViewDataSource,
																NSTableViewDelegate {

	static let shared = ChannelListWindowController(windowNibName: "ChannelListWindowController")

	@IBOutlet var tableView: NSTableView!

	@IBOutlet var c_onOff: NSSwitch!
	@IBOutlet var c_icon: NSImageView!
	@IBOutlet var c_titleLabel: NSTextField!
	@IBOutlet var c_urLabel: NSTextField!
	@IBOutlet var c_lastUpdateLabel: NSTextField!
	@IBOutlet var c_lastErrorLabel: NSTextField!

	@IBOutlet var noSelectionView: NSView!
	
	@IBOutlet var plusButton: THNSButtonBlock!
	@IBOutlet var minusButton: THNSButtonBlock!
	
	private var objectList: [[String: Any]]?
	private let todayDf = THTodayDateFormatter(todayFormat: "HMS", otherFormatter: DateFormatter(dateStyle: .medium, timeStyle: .medium))
	private var channelOnCreation: RssChannel?
	
	// MARK: -
	
	override func windowDidLoad() {
		super.windowDidLoad()
	
		self.window!.title = THLocalizedString("Channel List")
	
		plusButton.actionBlock = {() in
			self.channelOnCreation = RssChannel()
			self.updateUI()

			self.tableView.selectRowIndexes(IndexSet(integer: self.objectList!.count - 1), byExtendingSelection: false)
			self.tableView.scrollRowToVisible(self.objectList!.count - 1)
		}

		minusButton.actionBlock = {() in
			let row = self.tableView.selectedRow

			let object = self.objectList![row]
			let channel = object["channel"] as! Channel

			let title = THLocalizedString("Are you sure you want to delete \"") + channel.url!.th_reducedHost + "\""
			let msg = channel.url?.absoluteString
			let alert = NSAlert(withTitle: title, message: msg, buttons: [THLocalizedString("Delete"), THLocalizedString("Cancel")])

			alert.beginSheetModal(for: self.window!, completionHandler: {(response: NSApplication.ModalResponse) in
				if response == .alertFirstButtonReturn {
					DispatchQueue.main.async {
						RssChannelManager.shared.removeChannel(channel.identifier)
						self.updateUI()
					}
				}
			})
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
		let channels = RssChannelManager.shared.channels

		var objectList = [[String: Any]]()

		for channel in channels {
			objectList.append(["kind": 1, "channel": channel])
		}
	
		if let channel = channelOnCreation {
			objectList.append(["kind": 2, "channel": channel])
		}

		self.objectList = objectList
		self.tableView.reloadData()
	}

	private func updateUISelection() {
		let row = self.tableView.selectedRow

		minusButton.isEnabled = row != -1
		noSelectionView.isHidden = row != -1
		c_titleLabel.superview!.isHidden = row == -1
		
		if row == -1 {
			return
		}

		let selView = c_titleLabel.superview!
		if selView.superview == nil {
			selView.frame.size = noSelectionView.superview!.frame.size
			noSelectionView.superview!.addSubview(selView)
		}

		let object = objectList![row]
		let channel = object["channel"] as! Channel

		c_icon.image = THWebIconLoader.shared.icon(forHost: channel.url?.host, startUpdate: true, allowsGeneric: true)
		c_titleLabel.objectValue = channel.title
		c_onOff.state = channel.disabled == true ? .off : .on

		c_urLabel.objectValue = channel.url

		let lu = channel.lastUpdate
		c_lastUpdateLabel.stringValue = lu != nil ? todayDf.string(from: lu!) : "--"
		
		c_lastErrorLabel.stringValue = channel.lastError ?? "--"
	}
	
	private func reloadSelectedRow() {
		let row = self.tableView.selectedRow
		if row == -1 {
			return
		}
		
		tableView.th_reloadData(forRowIndexes: IndexSet(integer: row))
	}
	
	// MARK: -
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return objectList != nil ? objectList!.count : 0
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

//		let selectedRow = self.tableView.selectedRow

		let object = objectList![row]
		let channel = object["channel"] as! Channel
		
		let icon = THWebIconLoader.shared.icon(forHost: channel.url?.host, startUpdate: true, allowsGeneric: true)
		
		let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "cell_id"), owner: self) as! NSTableCellView

		cell.imageView?.image =  channel.disabled ? icon?.th_imageGray() : icon
		cell.textField?.stringValue = channel.url?.th_reducedHost ?? channel.url?.absoluteString ?? ""
//		cell.textField?.textColor = channel.lastError != nil ? .red : (selectedRow == row ? .white : .black)

		return cell
	}

	func tableViewSelectionDidChange(_ notification: Notification) {
		updateUISelection()
	}
	
	// MARK: -

	@IBAction func onOffAction(_ sender: NSSwitch) {
		let row = self.tableView.selectedRow
		if row == -1 {
			return
		}
		
		let disabled = sender.state == .off

		let object = objectList![row]
		let channel = object["channel"] as! Channel

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
		let kind = object["kind"] as! Int
		let channel = object["channel"] as! Channel

		let url = c_urLabel.stringValue.trimmingCharacters(in: .whitespaces)
	
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
		let channel = object["channel"] as! Channel

		RssChannelManager.shared.clean(channel: channel.identifier)
	
		RssChannelManager.shared.updateChannel(channel.identifier, completion: {() in
			self.updateUISelection()
		})
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
