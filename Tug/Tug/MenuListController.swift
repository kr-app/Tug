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

class MenuListController: NSViewController,	NSWindowDelegate,
																		NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate,
																		NSSearchFieldDelegate,
																		THHighlightedTableViewDelegateProtocol{

	@IBOutlet var headerView: HeaderView!
	@IBOutlet var headerLabel: NSTextField!
	@IBOutlet var searchField: NSSearchField!
	@IBOutlet var tableView: MenuTableView!

	var isShowing = false
	var isHidding = false

	private weak var delegate: MenuListControllerDelegateProtocol?
	private var myWindow: PWPaneWindow?
	private var objectList: [MenuObjectItem]?
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
		tableView.menu = NSMenu(title: "menu", delegate: self, autoenablesItems: false)
		tableView.doubleAction = #selector(tableViewDoubleAction)
		
		NotificationCenter.default.addObserver(self, selector: #selector(n_iconDownloaderDidLoad), name: THIconDownloader.didLoadNotification, object: nil)
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
	
	@objc func n_iconDownloaderDidLoad(_ notification: Notification) {
		guard 	let url = notification.userInfo?["url"] as? URL,
					let objectList = objectList
		else {
			return
		}

		if let firstIdx = objectList.firstIndex(where: { ($0.kind == .rss || $0.kind == .yt) && $0.item!.thumbnail == url }) {
			tableView.th_reloadData(forRowIndexes: IndexSet(integer: firstIdx), columnIndexes: nil)
		}
	}
	
	// MARK: -
	
	private func saveVisibleVisibleItems() {
//		func firstVisibleItem() -> ObjectItem? {
//			guard let objectList = objectList
//			else {
//				return nil
//			}
//
//			let visibleRows = self.tableView.rows(in: self.tableView.visibleRect)
//			if visibleRows.location < 3 {
//				return nil
//			}
//
//			for i in visibleRows.location..<visibleRows.location + visibleRows.length {
//				let object = objectList[i]
//				if object.kind == .rss {
//					return object
//				}
//			}
//
//			return nil
//		}
//
//		if let topItem = firstVisibleItem() {
//			UserDefaults.standard.set("\(topItem.channel!.identifier)}-{\(topItem.item!.identifier)", forKey: "PaneViewController-TopItem")
//		}
//		else {
//			UserDefaults.standard.removeObject(forKey: "PaneViewController-TopItem")
//		}
	}
	
	private func restoreVisitleItems() {
/*		guard 	let objectList = objectList,
					let topItem = UserDefaults.standard.string(forKey: "PaneViewController-TopItem")
		else {
			return
		}
	
		let channelId = topItem.components(separatedBy: "}-{").first!
		let itemId = topItem.components(separatedBy: "}-{").last!

		guard let idx = objectList.firstIndex(where: { $0.kind == 1 && $0.channel?.identifier == channelId && $0.item?.identifier == itemId })
		else {
			return
		}
		
		if objectList[idx].item!.checked == false {
			return
		}
		
		let vrect = tableView.rect(ofRow: idx)
		tableView.scrollToVisible(NSRect(vrect.origin.x, vrect.origin.y, 0.0, 0.0))*/
	}

	private func mark(checked: Bool? = nil, pinned: Bool? = nil, row: Int, item: ChannelItem, channel: Channel) {
		if let channel = channel as? RssChannel {
			RssChannelManager.shared.mark(checked: checked, pinned: pinned, item: item, channel: channel.identifier)
		}
		else if let channel = channel as? YtChannel {
			YtChannelManager.shared.mark(checked: checked, pinned: pinned, item: item, channel: channel.identifier)
		}

//		let cellView = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? MenuCellView
//		cellView?.updateCell(forObject: object)

		tableView.th_reloadData(forRowIndexes: IndexSet(integer: row))
		updateUIHeader()
	}

	private func delete(item: ChannelItem, channel: Channel) {
		if let channel = channel as? RssChannel {
			RssChannelManager.shared.removeItem(item, channel: channel.identifier)
		}
		else if let channel = channel as? YtChannel {
			YtChannelManager.shared.removeItem(item, channel: channel.identifier)
		}

		self.updateUI()
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
	
		tableView.startHighlightedTracking()
		win.makeFirstResponder(tableView)
		win.makeKeyAndOrderFront(nil)
		restoreVisitleItems()
	
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
			UserDefaults.standard.set(NSStringFromSize(win.frame.size), forKey: "PaneViewController-FrameSize")
		}
		
		saveVisibleVisibleItems()
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

		let ytUnread = YtChannelManager.shared.unreadedCount()

		let nbItems = objectList?.count ?? 0
		headerLabel.stringValue = "\(nbu + ytUnread)/\(nbItems)"
	}
	
	private func updateUIIObjectList() {

		func itemFromChannelsOnError(_ channels: [Channel]) -> MenuObjectItem {
			let channel = channels.first!

			var title: String!
			if channels.count == 1 {
				title = "\"\(channel.displayTitle())\" " + THLocalizedString("is on error") + "\n" + (channel.lastError ?? "?")
			}
			else {
				title = "\(channels.count) " + THLocalizedString("channels on error")
				title += "\n" + (channel.lastError ?? "?")
			}

			return MenuObjectItem(kind: .error, error: title)
		}

		let showRss = true
		let showYt = true

		var objectList = [MenuObjectItem]()

		if showYt {

			if let channels = YtChannelManager.shared.channelsOnError() {
				objectList.append(itemFromChannelsOnError(channels))
			}

			let unreadedChannels = YtChannelManager.shared.unreadedChannels()
			for channel in unreadedChannels {
				for item in channel.items.filter( {$0.checked == false }) {
					objectList.append(MenuObjectItem(kind: .yt, channel: channel, item: item))
				}
			}
		}

		if showRss == true {
			let recentRef = RssChannelManager.shared.recentRefDate()
			let channels = RssChannelManager.shared.channels//.wallChannels()//.wallChannels(withDateRef: recentRef)
			var items = [(channel: Channel, item: ChannelItem)]()

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

			// On error
			if let channels = RssChannelManager.shared.channelsOnError() {
				objectList.append(itemFromChannelsOnError(channels))
			}

	//		if menu.th_lastItem()?.isSeparatorItem == false {
	//			menu.addItem(NSMenuItem.separator())
	//		}

			// Items

			let unreadedItems = items.filter({ $0.item.pinned == false && $0.item.checkedDate == nil })
			if unreadedItems.count > 0 {
				for item in unreadedItems {
					objectList.append(MenuObjectItem(kind: .rss, channel: item.channel, item: item.item))
				}
//				objectList.append(ObjectItem(kind: .separator))
			}

			if showYt {
				let recentRef = Date().timeIntervalSinceReferenceDate - 1.5.th_day
				let recentChannels = YtChannelManager.shared.recentChannels(afterDate: recentRef)

				for channel in recentChannels {
					for item in channel.items {
						if item.checked == true && item.isRecent(refDate: recentRef) == true {
							objectList.append(MenuObjectItem(kind: .yt, channel: channel, item: item))
						}
					}
				}
			}

			let pinnedItems = items.filter({ $0.item.pinned == true })
			if pinnedItems.count > 0 {
				for item in pinnedItems {
					objectList.append(MenuObjectItem(kind: .rss, channel: item.channel, item: item.item))
				}
//				objectList.append(MenuObjectItem(kind: .separator))
			}

			for item in items.filter({ $0.channel.disabled == false && $0.item.pinned == false && $0.item.checkedDate != nil }) {
				objectList.append(MenuObjectItem(kind: .rss, channel: item.channel, item: item.item))
			}
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

	private func objectItem(at row: Int) -> MenuObjectItem? {
		return row == -1 ? nil : objectList?[row]
	}

	// MARK: -
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return objectList?.count ?? 0
	}

	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		return objectList![row]
	}
	
	func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {

		let object = objectList![row]
		
		if object.kind == .rss || object.kind == .yt {
			let rowId = NSUserInterfaceItemIdentifier(rawValue: "rowId")
			var rowView = tableView.makeView(withIdentifier: rowId, owner: self) as? MenuListRowView
			
			if rowView == nil {
				rowView = MenuListRowView(frame: .zero)
				rowView!.identifier = rowId
			}
			else {
				rowView!.isHighlightedRow = false
			}

			return rowView!
		}
		else if object.kind == .error {
			let rowView = MenuListErrRowView(frame: .zero)
			return rowView
		}
		else if object.kind == .separator {
			let rowView = MenuListSepRowView(frame: .zero)
			return rowView
		}
		
		return nil
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let object = objectList![row]

		if object.kind == .rss || object.kind == .yt {
			let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "normal_cell_id"), owner: self) as! MenuCellView
			cell.updateCell(forObject: object)
			return cell
		}
		else if object.kind == .error {
			let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "onerror_cell_id"), owner: self) as! NSTableCellView

			cell.textField!.textColor = .white
			cell.textField!.objectValue =  object.error

			return cell
		}
		else if object.kind == .separator {
			let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "sep_cell_id"), owner: self) as! NSTableCellView
			return cell
		}
		
		return nil
	}
	
	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		let object = objectList![row]
		return object.kind == .separator ? 19.0 : object.kind == .error ? 57.0 : tableView.rowHeight
	}

	func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
		let object = objectList![row]
		return object.kind == .rss || object.kind == .yt
	}
	
	func tableViewSelectionDidChange(_ notification: Notification) {
		tableView.updateHighLightedRowFromSelectionDidChange()
	}
	
	func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {

		let object = objectList![row]
		
		if object.kind == .rss || object.kind == .yt {
	
			let channel = object.channel!
			let item = object.item!

			if edge == .leading {
				let checked = item.checked
				let cTitle = checked == true ? THLocalizedString("Unread") : THLocalizedString("Read")
			
				let checkedRa = NSTableViewRowAction(style: .regular, title: cTitle, handler: { (action: NSTableViewRowAction, row: Int) in
					self.mark(checked: !checked, row: row, item: item, channel: channel)
					tableView.rowActionsVisible = false
				})
				checkedRa.backgroundColor = .cyan

				let pinned = item.pinned
				let pTitle = pinned == true ? THLocalizedString("Unpin") : THLocalizedString("Pin")

				let pinRa = NSTableViewRowAction(style: .regular, title: pTitle, handler: { (action: NSTableViewRowAction, row: Int) in
					self.mark(pinned: !pinned, row: row, item: item, channel: channel)
					tableView.rowActionsVisible = false
				})
				pinRa.backgroundColor = .purple

				return [checkedRa, pinRa]
			}
			else if edge == .trailing {
				let ra = NSTableViewRowAction(style: .destructive, title: THLocalizedString("Delete"), handler: { (action: NSTableViewRowAction, row: Int) in
					self.delete(item: item, channel: channel)
					tableView.rowActionsVisible = false
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

			let rowView = tableView.rowView(atRow: highlightedRow , makeIfNecessary: false) as? MenuListRowView
			rowView?.isHighlightedRow = object.kind == .rss || object.kind == .yt
		}

		if tableView.selectedRow != highlightedRow {
			tableView.deselectRow(tableView.selectedRow)
		}

		if highlightedRow != -1 {
			let object = objectList![highlightedRow]

			if object.kind == .rss {
				let channel = object.channel!
				let item = object.item!

				RssChannelManager.shared.mark(checked: true, item: item, channel: channel.identifier)

				let cellView = tableView.view(atColumn: 0, row: highlightedRow, makeIfNecessary: false) as? MenuCellView
				cellView?.updateCell(forObject: object)
				
				updateUIHeader()
			}
		}

		openPreviewForRow(UserPreferences.shared.previewHighlightMode == 1 ? highlightedRow : -1)
	}

	// MARK: -
	
	func cancelUpdatePreview() {
		previewItemIndex = -1
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector:#selector(openPreviewOfCurrentItem), object: nil)
	}
	
	private func closePreview(animated: Bool) {
		previewItemIndex = -1
		PPPaneRequester.shared.requestClose(withAnimation: animated)
	}

	private func hidePreview(animated: Bool) {
		previewItemIndex = -1
		PPPaneRequester.shared.requestHide(withAnimation: animated)
	}
	
	private func previewItemIdFromObject(_ object: MenuObjectItem) -> String? {

		if object.kind == .rss || object.kind == .yt {
			let channel = object.channel!
			let item = object.item!
			return "{" + channel.identifier + "}" + "{" + item.identifier + "}"
		}

		return nil
	}

	@objc func openPreviewOfCurrentItem() {
		var previewItemId: String?
		
		var channel: Channel?
		var item: ChannelItem?

		if previewItemIndex != -1 {
			let object = objectList![previewItemIndex]

			previewItemId = previewItemIdFromObject(object)

			if object.kind == .rss || object.kind == .yt {
				channel = object.channel
				item = object.item
			}
		}

		if channel == nil || item?.link == nil {
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

		if let channel = channel as? RssChannel {
			//RssChannelManager.shared.mark(checked: true, item: item, channel: channel.identifier)
		}
		else if let channel = channel as? YtChannel {
			YtChannelManager.shared.mark(checked: true, item: item!, channel: channel.identifier)
		}

//		let rowRect = tableView.rect(ofRow: previewItemIndex)
//
//		var pt = NSPoint(rowRect.origin.x, rowRect.origin.y + (rowRect.size.height / 2.0).rounded(.down))
//		pt = tableView.perform(Selector("convertPointToBase"), with: Unmanaged(pt))
//		//NSPoint p=[self.view.window.contentView convertPoint:rowPoint toView:self.tableView]
//		pt = tableView.window!.convertToScreen(NSRect(pt.x, pt.y, 0.0, 0.0)).origin

		var pt = tableView.convertWindowPoint(forRow: previewItemIndex)
		pt.y = (self.view.window!.frame.size.height / 2.0).rounded(.down)

		PPPaneRequester.shared.requestShowAtPoint(pt, withData: item!.link!.absoluteString)
	}
	
	private func openPreviewForRow(_ row: Int) {

		if self.previewItemId != nil {
			cancelUpdatePreview()

			if row == -1 {
				if NSMouseInRect(NSEvent.mouseLocation, self.view.window!.frame, false) == false {
					return
				}
			}

			self.previewItemIndex = row
			perform(#selector(openPreviewOfCurrentItem), with: nil, afterDelay: 0.01)
		}
		else {
			cancelUpdatePreview()
			self.previewItemIndex = row

			if row == -1 {
				return
			}

			perform(#selector(openPreviewOfCurrentItem), with: nil, afterDelay: 0.01)
		}

	}
	
	// MARK: -

	private func openInWebBrower(_ object: MenuObjectItem?) {

		openPreviewForRow(-1)

		guard let object = object
		else {
			return
		}

		if object.kind == .rss || object.kind == .yt {
			let channel = object.channel!
			let item = object.item!

			guard let link = item.link
			else {
				return
			}

			if let channel = channel as? RssChannel {
				RssChannelManager.shared.mark(checked: true, item: item, channel: channel.identifier)
			}
			else if let channel = channel as? YtChannel {
				YtChannelManager.shared.mark(checked: true, item: item, channel: channel.identifier)
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

			delegate?.paneViewControllerDidPresentExternalItem(self)
		}
	}

	// MARK: -
	
	@IBAction func tableViewAction(_ sender: NSTableView) {
		if UserPreferences.shared.actionOnItemClick == "openInBrowser" {
			openInWebBrower(objectItem(at: sender.clickedRow))
		}
		else if UserPreferences.shared.actionOnItemClick != "none" {
			openPreviewForRow(sender.clickedRow)
		}
	}

	@objc func tableViewDoubleAction(_ sender: NSTableView) {
		openInWebBrower(objectItem(at: sender.clickedRow))
	}
	
	// MARK: -
	
	func menuNeedsUpdate(_ menu: NSMenu) {
		menu.removeAllItems()
		
		let row = tableView.clickedRow
		if row == -1 {
			return
		}

		let object = objectList![row]

		if object.kind == .rss || object.kind == .yt {

			let channel = object.channel!
			let item = object.item!

			menu.addItem(THMenuItem(title: THLocalizedString("Open Link"), block: {() in
				self.openInWebBrower(object)
			}))

			menu.addItem(NSMenuItem.separator())

			let checked = item.checked
			menu.addItem(THMenuItem(title: checked ? THLocalizedString("Unread") : THLocalizedString("Read"), block: {() in
				self.mark(checked: !checked, row: row, item: item, channel: channel)
			}))

			let pinned = item.pinned
			menu.addItem(THMenuItem(title: pinned ? THLocalizedString("Unpin") : THLocalizedString("Pin"), block: {() in
				self.mark(pinned: !pinned, row: row, item: item, channel: channel)
			}))

			menu.addItem(NSMenuItem.separator())

			menu.addItem(THMenuItem(title: THLocalizedString("Delete"), block: {() in
				self.delete(item: item, channel: channel)
			}))
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
