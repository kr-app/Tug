// MenuListController.swift

import Cocoa

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------
class MenuBgView : NSVisualEffectView {
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------
class MenuTableView: THHighlightedTableView {
	override var acceptsFirstResponder: Bool { get { return true } }
	override var canBecomeKeyView: Bool { get { return true } }
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------
protocol MenuListControllerDelegateProtocol: AnyObject {
	func paneViewControllerDidResignKeyWindow(_ menuListController: MenuListController)
	func paneViewControllerDidPresentExternalItem(_ menuListController: MenuListController)
}

class MenuListController: NSViewController,
																		NSWindowDelegate,
																		NSTableViewDataSource,
																		NSTableViewDelegate,
																		NSSearchFieldDelegate {

	@IBOutlet var headerView: HeaderView!
	@IBOutlet var headerLabel: NSTextField!
	@IBOutlet var searchField: NSSearchField!
	@IBOutlet var tableView: MenuTableView!

	var isShowing = false
	var isHidding = false

	var recentRef: TimeInterval = 0.0

	private weak var delegate: MenuListControllerDelegateProtocol?
	private var myWindow: PWPaneWindow?
	private var objectList: [[String: Any]]?
	private var searchedText: String?

	private var previewItemIndex = -1
	private var previewItemId: String?
	
	// MARK: -
	
	init(delegate: MenuListControllerDelegateProtocol) {
		super.init(nibName: "MenuListController", bundle: nil)
		self.delegate = delegate
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: -
	
	override func loadView() {
		super.loadView()

//		self.view.wantsLayer = true
//		self.view.layer!.cornerRadius = 8.0

		(self.view as! NSVisualEffectView).maskImage = NSVisualEffectView.th_maskImage(cornerRadius: 8.0)
//		(self.view as NSVisualEffectView)	   visualEffectView.state = .active
//		(self.view as NSVisualEffectView)  visualEffectView.material = .dark

//		searchField.appearance = NSAppearance(named: .darkAqua)
		
		tableView.backgroundColor = .clear
		//tableView.menu=_paneRightMenu.menu
		tableView.doubleAction = #selector(tableViewDoubleAction)
	}
	
	deinit {
		THLogInfo("")
	}

	// MARK: -

	func windowDidResignKey(_ notification: Notification) {
		if let win = notification.object as? PWPaneWindow {
			if myWindow != win {
				return
			}
			delegate?.paneViewControllerDidResignKeyWindow(self)
		}
	}
	
	func windowWillStartLiveResize(_ notification: Notification) {
		if let win = notification.object as? PWPaneWindow {
			if myWindow != win || isHidding == true || isShowing == true {
				return
			}

			if win.ignoresUserFrameResizing == true {
				return
			}

			cancelUpdatePreview()
			hidePreview(animated: true)
		}
	}
	
	// MARK: -

	func canHidePaneWindow() -> Bool {
		if myWindow == nil {
			return true
		}
		return myWindow!.attachedSheet == nil
	}

	func showWindow(inZone: NSRect, onScreen screen: NSScreen, completion: @escaping () -> Void) {
		if myWindow != nil || isShowing == true {
			completion()
			return
		}

		isShowing = true

		var zone = inZone
		if zone.origin.x < 0.0 {
			zone.origin.x *= -1.0
		}
		
		let visibleRect = screen.visibleFrame
		var vSize = self.view.frame.size

		if let frameSizeStr = UserDefaults.standard.string(forKey: "PaneViewController-FrameSize") {
			vSize.width = NSSizeFromString(frameSizeStr).width
			if vSize.width < PWPaneWindow.winMinWidthSize {
				vSize.width = PWPaneWindow.winMinWidthSize
			}
		}

		var wFrame = NSRect(0.0, zone.origin.y - vSize.height, vSize.width, vSize.height)

		let sens: NSTextAlignment = (zone.origin.x + vSize.width + PWPaneWindow.winRightMargin) < (/*visibleRect.origin.x +*/ visibleRect.size.width) ? .right : .left
		wFrame.origin.x = zone.origin.x + (sens ==  .left ? (zone.size.width - wFrame.size.width) : 0.0)
		wFrame.origin.x += sens == .left ? 2.0 : -2.0
		
		let win = PWPaneWindow(		contentRect: wFrame,
														styleMask: [.borderless,.fullSizeContentView, .resizable],
														backing: .buffered,
														defer: true,
														screen: screen)
//		win.level = .statusBar // NSStatusWindowLevel
		win.hasShadow = true
		win.backgroundColor = .clear
		win.isOpaque = false
		win.delegate = self
		win.contentView = self.view
		win.alphaValue = 0.0
		win.sensSrientation =  sens
		myWindow = win
		
		updateUI()

		self.tableView.startHighlightedTracking()
		win.makeFirstResponder(self.tableView)
		win.makeKeyAndOrderFront(nil)

		NSAnimationContext.runAnimationGroup({ (context) in
			context.duration = 0.1
			win.animator().alphaValue = 1.0
		}, completionHandler: {() in
			self.isShowing = false
			completion()
		})
	
	}

	func hideWindow(completion: @escaping () -> Void) {
		guard let win = myWindow, isHidding == false
		else {
			completion()
			return
		}

		isHidding = true

		if win.hasUserCustomFrameSize {
			UserDefaults.standard.setValue(NSStringFromSize(win.frame.size), forKey: "PaneViewController-FrameSize")
		}

		self.tableView.stopHighlightedTracking()
		closePreview(animated: true)
		
		win.delegate = nil
		myWindow = nil

		NSAnimationContext.runAnimationGroup({ (context) in
			context.duration = 0.1
			win.animator().alphaValue = 0.0
		}, completionHandler: {() in
			self.isHidding = false
			win.orderOut(nil)
			completion()
		})

	}

	// MARK: -
	
	private func updateUI() {
		hidePreview(animated: true)

		updateUIIObjectList()
		updateUIHeader()

		sizeToFitWindow(animated: false)
	}
	
	private func updateUIHeader() {
		
		if searchedText != nil {
			headerLabel.stringValue = "\(objectList?.count)"
			return
		}
		
		let channels = RssChannelManager.shared.channels//.wallChannels()//.wallChannels(withDateRef: recentRef)

		var nbu = 0
		for channel in channels {
			nbu += channel.unreaded()
		}

		let nbItems = objectList == nil ? 0 : objectList?.count
		headerLabel.stringValue = "\(nbu)/\(nbItems)"
	}
	
	private func updateUIIObjectList() {
		
		recentRef = RssChannelManager.shared.recentRefDate()
		let channels = RssChannelManager.shared.channels//.wallChannels()//.wallChannels(withDateRef: recentRef)
		var items = [(channel: RssChannel, item: RssChannelItem)]()

		for channel in channels {

			if searchedText != nil && channel.contains(stringValue: searchedText!) == true {
				for item in channel.items {
					items.append((channel: channel, item: item))
				}
				continue
			}

			for item in channel.items/*.filter({ $0.checked == false }) */{
				if item.checked == true && item.isRecent(refDate: recentRef) == false {
					continue
				}
				if searchedText != nil && item.contains(stringValue: searchedText!) == false {
					continue
				}
				items.append((channel: channel, item: item))
//				if max >= 5 {
//					break
//				}
//				max += 1
			}
		}

		items.sort(by: {
			let rcv0 = $0.item.received!
			let rcv1 = $1.item.received!
			
			if rcv0 == rcv1 {
				if let up0 = $0.item.published, let up1 = $1.item.published {
					return up0 > up1
				}
			}

			return rcv0 > rcv1
		})

		var objectList = [[String: Any]]()

		// On error
		let channelsOnError = RssChannelManager.shared.channelsOnError()
		if channelsOnError.count > 0 {
			objectList.append(["kind": 2, "channels": channelsOnError])
		}

//		if menu.th_lastItem()?.isSeparatorItem == false {
//			menu.addItem(NSMenuItem.separator())
//		}

		// Items
		
		let unreadedItems = items.filter({ $0.item.pinned == false && $0.item.checkedDate == nil })
		if unreadedItems.count > 0 {
			for item in unreadedItems {
				objectList.append(["kind": 1, "channel": item.channel, "item": item.item])
			}
			objectList.append(["kind": 3])
		}

		let pinnedItems = items.filter({ $0.item.pinned == true })
		if pinnedItems.count > 0 {
			for item in pinnedItems {
				objectList.append(["kind": 1, "channel": item.channel, "item": item.item])
			}
			objectList.append(["kind": 3])
		}

		for item in items.filter({ $0.item.pinned == false && $0.item.checkedDate != nil }) {
			objectList.append(["kind": 1, "channel": item.channel, "item": item.item])
		}

		self.objectList = objectList
		self.tableView.reloadData()
	}

	private func sizeToFitWindow(animated: Bool) {
		guard 	let win = self.view.window as? PWPaneWindow,
					let screen = win.screen
		else {
			return
		}

		var headH = headerView.frame.size.height // self.topBarView.frame.size.height
		headH += 6.0

		let tableViewH = CGFloat(self.tableView.numberOfRows) * self.tableView.rowHeight
//		for i in 0..<self.tableView.numberOfRows {
//			tableViewH += tableView(self.tableView, heightOfRow: i)
//		}

		let maxH = (screen.visibleFrame.size.height - 20.0).rounded(.down)
		var wRect = win.frame

		var nH = headH + tableViewH + tableView.enclosingScrollView!.frame.origin.y
		if nH > maxH {
			nH = maxH
		}

		wRect.origin.y += wRect.size.height - nH
		wRect.size.height = nH

		win.ignoresUserFrameResizing = true
		win.setFrame(wRect, display: true, animate: animated)
	}

	// MARK: -
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return objectList != nil ? objectList!.count : 0
	}

	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		return objectList![row]
	}
	
	func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {

		let object = objectList![row]
		let kind = object["kind"] as! Int
		
		if kind == 1 {
			let row_id = NSUserInterfaceItemIdentifier(rawValue: "row_id")
			var rowView = tableView.makeView(withIdentifier: row_id, owner: self) as? MenuListRowView
			if rowView == nil {
				rowView = MenuListRowView(frame: .zero)
				rowView!.identifier = row_id
			}
			return rowView!
		}
		else if kind == 2 {
			let rowView = MenuListErrRowView(frame: .zero)
			return rowView
		}
		else if kind == 3 {
			let rowView = MenuListSepRowView(frame: .zero)
			return rowView
		}
		
		return nil
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let object = objectList![row]
		let kind = object["kind"] as! Int

		if kind == 1 {
			let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "normal_cell_id"), owner: self) as! MenuCellView
			cell.updateCell(forObject: object)
			return cell
		}
		else if kind == 2 {
			let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "onerror_cell_id"), owner: self) as! NSTableCellView

			let channels = object["channels"] as! [RssChannel]

			var s: String!
			if channels.count == 1 {
				s = "\(channels.first!.url.th_reducedHost) " + THLocalizedString("on error") + "\n"
				s += (channels.first?.lastError) ?? ""
			}
			else {
				s = "\(channels.count) " + THLocalizedString("channels on error") + "\n"
				s += (channels.first!.lastError) ?? ""
			}

			cell.textField!.textColor = .white
			cell.textField!.objectValue =  s

			return cell
		}
		else if kind == 3 {
			let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "sep_cell_id"), owner: self) as! NSTableCellView
			return cell
		}
		
		return nil
	}
	
	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		let object = objectList![row]
		let kind = object["kind"] as! Int
		return kind == 3 ? 19.0 : kind == 2 ? 57.0 : tableView.rowHeight
	}

	func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
		let object = objectList![row]
		let kind = object["kind"] as! Int
		return kind == 1
	}
	
	func tableViewSelectionDidChange(_ notification: Notification) {
		tableView.updateHighLightedRowFromSelectionDidChange()
	}
	
	func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {

		let object = objectList![row]
		let kind = object["kind"] as! Int
		
		if kind == 1 {
	
			let channel = object["channel"] as! RssChannel
			let item = object["item"] as! RssChannelItem
			
			if edge == .leading {
				
				let pinned = item.pinned
				let title = pinned == true ? THLocalizedString("Unpin") : THLocalizedString("Pin")
				
				let ra = NSTableViewRowAction(style: .regular, title: title, handler: { (action: NSTableViewRowAction, row: Int) in
					RssChannelManager.shared.markPinned(pinned: !pinned, item: item, ofChannel: channel.identifier)

//					let cellView = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? MenuCellView
//					cellView?.updateCell(forObject: object)
	
					self.tableView.th_reloadData(forRowIndexes: IndexSet(integer: row))
					self.updateUIHeader()

					tableView.rowActionsVisible = false
				})
				ra.backgroundColor = .purple
				
				return [ra]
			}

			else if edge == .trailing {
				let ra = NSTableViewRowAction(style: .destructive, title: THLocalizedString("Delete"), handler: { (action: NSTableViewRowAction, row: Int) in

					RssChannelManager.shared.removeItem(item, ofChannel: channel.identifier)
					tableView.rowActionsVisible = false

					self.updateUI()
				})
				return [ra]
			}
		}

		return []
	}

	@objc func highlightedTableView(_ tableView: THHighlightedTableView, didHighlightRow highlightedRow : Int, previousHighlightedRow: Int) {

		if previousHighlightedRow != -1 {
			let rowView = tableView.rowView(atRow: previousHighlightedRow, makeIfNecessary: false) as? MenuListRowView
			rowView?.isHighlightedRow = false
		}

		if highlightedRow != -1 {
			let object = objectList![highlightedRow]
			let kind = object["kind"] as! Int

			let rowView = tableView.rowView(atRow: highlightedRow , makeIfNecessary: false) as? MenuListRowView
			rowView?.isHighlightedRow = kind == 1
		}

		if tableView.selectedRow != highlightedRow {
			tableView.deselectRow(tableView.selectedRow)
		}

		if highlightedRow != -1 {
			let object = objectList![highlightedRow]
			let kind = object["kind"] as! Int

			if kind == 1 {
				let channel = object["channel"] as! RssChannel
				let item = object["item"] as! RssChannelItem

				RssChannelManager.shared.markChecked(item: item, ofChannel: channel.identifier)

				let cellView = tableView.view(atColumn: 0, row: highlightedRow, makeIfNecessary: false) as? MenuCellView
				cellView?.updateCell(forObject: object)
				
				updateUIHeader()
			}
		}

		updatePreviewForRow(UserPreferences.shared.previewHighlightMode == 1 ? highlightedRow : -1)
	}

	// MARK: -
	
	func cancelUpdatePreview() {
		previewItemIndex = -1
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector:#selector(updatePreview), object: nil)
	}
	
	private func closePreview(animated: Bool) {
		previewItemIndex = -1
		PPPaneRequester.shared.requestClose(withAnimation: animated)
	}

	private func hidePreview(animated: Bool) {
		previewItemIndex = -1
		PPPaneRequester.shared.requestHide(withAnimation: animated)
	}
	
	private func previewItemIdFromObject(_ object: [String: Any]) -> String? {

		let kind = object["kind"] as! Int

		if kind == 1 {
			let channel = object["channel"] as! RssChannel
			let item = object["item"] as! RssChannelItem
			return "{" + channel.url.absoluteString + "}" + "{" + item.identifier + "}"
		}

		return nil
	}

	@objc func updatePreview() {
		var previewItemId: String?
		var link: URL?

		if previewItemIndex != -1 {
			let object = objectList![previewItemIndex]
			let kind = object["kind"] as! Int

			previewItemId = previewItemIdFromObject(object)

			if kind == 1 {
				let item = object["item"] as! RssChannelItem

				link = item.link
			}
		}

		if link == nil {
			previewItemId = nil
		}

		if self.previewItemId == previewItemId {
			return
		}

		self.previewItemId = previewItemId

		if previewItemId == nil {
			hidePreview(animated: true)
			return
		}

//		let rowRect = tableView.rect(ofRow: previewItemIndex)
//
//		var pt = NSPoint(rowRect.origin.x, rowRect.origin.y + (rowRect.size.height / 2.0).rounded(.down))
//		pt = tableView.perform(Selector("convertPointToBase"), with: Unmanaged(pt))
//		//NSPoint p=[self.view.window.contentView convertPoint:rowPoint toView:self.tableView]
//		pt = tableView.window!.convertToScreen(NSRect(pt.x, pt.y, 0.0, 0.0)).origin

		var pt = self.tableView.convertWindowPoint(ofRow: previewItemIndex)
		pt.y = (self.view.window!.frame.size.height / 2.0).rounded(.down)

		PPPaneRequester.shared.requestShowAtPoint(pt, withData: link!.absoluteString)
	}
	
	private func updatePreviewForRow(_ row: Int) {

		if self.previewItemId != nil {
			cancelUpdatePreview()

			if row == -1 {
				if NSMouseInRect(NSEvent.mouseLocation, self.view.window!.frame, false) == false {
					return
				}
			}

			self.previewItemIndex = row
			perform(#selector(updatePreview), with: nil, afterDelay: 0.01)
		}
		else {
			cancelUpdatePreview()
			self.previewItemIndex = row

			if row == -1 {
				return
			}

			perform(#selector(updatePreview), with: nil, afterDelay: 0.01)
		}

	}

	// MARK: -
	
	@IBAction func tableViewAction(_ sender: NSTableView) {
		if UserPreferences.shared.actionOnItemClick == "openInBrowser" {
			tableViewDoubleAction(sender)
		}
		else if UserPreferences.shared.actionOnItemClick != "none" {
			updatePreviewForRow(sender.selectedRow)
		}
	}

	@objc func tableViewDoubleAction(_ sender: NSTableView) {
		
		updatePreviewForRow(-1)

		if sender.clickedRow == -1 {
			return
		}

		let object = objectList![sender.clickedRow]
		let kind = object["kind"] as! Int
		
		if kind == 1 {

			let channel = object["channel"] as! RssChannel
			let item = object["item"] as! RssChannelItem

			guard let link = item.link
			else {
				return
			}

			RssChannelManager.shared.markChecked(item: item, ofChannel: channel.identifier)

			DispatchQueue.main.async {
				if THSafariScriptingTools.createWindowIfNecessary() == false {
					THLogError("createWindowIfNecessary == false")
				}

				THOpenInBrowser.shared.open(url: link, completion: {(ok: Bool) in
					if ok == false {
						THLogError("open == false link:\(link)")
					}
				})
			}
			
			delegate?.paneViewControllerDidPresentExternalItem(self)
		}

	}
	
	// MARK: -

	@IBAction func searchFieldAction(_ sender: NSSearchField) {
	}

	func controlTextDidChange(_ notification: Notification) {
		if let sender = notification.object as? NSSearchField {
			searchedText = sender.stringValue.trimmingCharacters(in: .whitespaces).isEmpty ? nil : sender.stringValue
			updateUI()
		}
	}
	
	
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------
