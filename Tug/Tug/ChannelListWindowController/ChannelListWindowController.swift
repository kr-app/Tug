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
fileprivate struct ObjectItem {
	let kind: Int
	let channel: Channel
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

			let object = self.objectList![row]
			let channel = object.channel

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
		var objectList = [ObjectItem]()

		for channel in RssChannelManager.shared.channels {
			objectList.append(ObjectItem(kind: 1, channel: channel))
		}

		for channel in YtChannelManager.shared.channels {
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
			let channel = object.channel

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
	
	// MARK: -
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return objectList?.count ?? 0
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

//		let selectedRow = self.tableView.selectedRow

		let object = objectList![row]
		let channel = object.channel
		
		let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "cell_id"), owner: self) as! NSTableCellView

		var icon: NSImage?

		if object.kind == 1 {
			icon = THWebIconLoader.shared.icon(forHost: channel.url?.host, startUpdate: true, allowsGeneric: true)
			cell.textField?.stringValue = channel.url?.th_reducedHost ?? channel.url?.absoluteString ?? ""
		}
		else if object.kind == 2 {
			icon = THWebIconLoader.shared.icon(forHost: channel.link?.host, startUpdate: true, allowsGeneric: true)
			cell.textField?.stringValue = channel.title ?? channel.link?.th_reducedHost ?? ""
		}

		cell.imageView?.image =  channel.disabled ? icon?.th_imageGray() : icon
//		cell.textField?.textColor = channel.lastError != nil ? .red : (selectedRow == row ? .white : .black)

		return cell
	}

	func tableViewSelectionDidChange(_ notification: Notification) {
		updateUISelection()
	}
	
	// MARK: -

	func menuNeedsUpdate(_ menu: NSMenu) {
		menu.removeAllItems()

		let row = tableView.clickedRow
		if row == -1 {
			return
		}

		let object = objectList![row]

		menu.addItem(THMenuItem(title: THLocalizedString("Reveal in Finder"), block: {() in
			if object.kind == 1 {
				RssChannelManager.shared.revealFile(channel: object.channel.identifier)
			}
			else if object.kind == 2 {
				YtChannelManager.shared.revealFile(channel: object.channel.identifier)
			}
		}))

		menu.addItem(NSMenuItem.separator())

		menu.addItem(THMenuItem(title: THLocalizedString("Remove"), block: {() in
		}))
	}

	// MARK: -

	@IBAction func onOffAction(_ sender: NSSwitch) {
		let row = self.tableView.selectedRow
		if row == -1 {
			return
		}
		
		let disabled = sender.state == .off

		let object = objectList![row]
		let channel = object.channel

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
		let channel = object.channel

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
		let channel = object.channel

		RssChannelManager.shared.clean(channel: channel.identifier)
	
		RssChannelManager.shared.updateChannel(channel.identifier, completion: {() in
			self.updateUISelection()
		})
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
