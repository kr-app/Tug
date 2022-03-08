// MenuCellView.swift

import Cocoa

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------
class MenuListRowView: THHighlightedTableRowView {

	override func drawBackground(in dirtyRect: NSRect) {
		let frameSz = self.frame.size
		
		if isHighlightedRow == true {
			let isDark = self.effectiveAppearance.name == .darkAqua

			NSColor(calibratedWhite: isDark ? 0.1 : 0.15, alpha: 1.0).set()
			NSBezierPath.fill(NSRect(0.0, 0.0, frameSz.width, frameSz.height))
		}
		else {
//			NSColor.clear.set()
//			NSBezierPath.fill(NSRect(0.0, 0.0, frameSz.width, frameSz.height))
		}
	}

	override func drawSelection(in dirtyRect: NSRect) {
		let frameSz = self.frame.size

		NSColor(calibratedWhite: 0.0, alpha: 1.0).set()
		NSBezierPath.fill(NSRect(0.0, 0.0, frameSz.width, frameSz.height))
	}

}

class MenuListErrRowView: NSTableRowView {
	override func drawBackground(in dirtyRect: NSRect) {
		let frameSz = self.frame.size
		TH_RGBCOLOR(180,25,0).set()
		NSBezierPath.fill(NSRect(0.0, 0.0, frameSz.width, frameSz.height))
	}
}

class MenuListSepRowView: NSTableRowView {

//	override func drawBackground(in dirtyRect: NSRect) {
//		let frameSz = self.frame.size
//
//		NSColor(calibratedWhite: 0.8, alpha: 1.0).set()
//		NSBezierPath.fill(NSRect(0.0, (frameSz.height / 2.0).rounded(.down), frameSz.width, 1.0))
//	}

}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------
class MenuCellView : THHighlightedTableCellView {

	@IBOutlet var infoLabel: NSTextField!

	private static let pub_df = DateFormatter(dateFormat: "MMM dd, HH:mm")
	private static let todat_df = THTodayDateFormatter(todayFormat: "HM")
	private static let ago_df = RelativeDateTimeFormatter(withUnitsStyle: .short)
	
	private var object: ObjectItem?
	private var currentBackgroundStyle: NSView.BackgroundStyle = .normal

	override var backgroundStyle: NSView.BackgroundStyle { didSet {
		if backgroundStyle != currentBackgroundStyle {
			currentBackgroundStyle = backgroundStyle
			updateCellFromObject()
		}
	}}

	override func updateHighlighted() {
		updateCellFromObject()
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()

		imageView?.wantsLayer = true
		imageView?.layer?.cornerRadius = 8.0
		imageView?.layer?.masksToBounds = true
	}

	func updateCell(forObject object: ObjectItem) {
		self.object = object
		updateCellFromObject()
	}

	private func updateCellFromObject() {
		guard let object = object
		else {
			return
		}
		
		if object.kind == 1 {
			
			let channel = object.channel!
			let item = object.item!

			//let isDark = self.effectiveAppearance.name == .darkAqua
			let isHighlighted = isHighlightedRow || self.backgroundStyle == .emphasized
			let itemColor = isHighlighted == true ? .white : item.checked ? NSColor(calibratedWhite: 0.2, alpha: 1.0): .black

			// icon
			var img = THIconDownloader.shared.icon(atURL: item.thumbnail, startUpdate: true)
			if img == nil {
				img = THWebIconLoader.shared.icon(forHost: channel.webLink?.host ?? channel.url.host, startUpdate: true, allowsGeneric: true)
			}
			if isHighlighted == false && item.checked == true && item.pinned == false {
				img = img?.th_imageGray()//.th_image(withCorner: 6.0)
			}

			imageView!.image = img
			imageView!.alphaValue = (isHighlighted == false && item.checked == true) ? 0.9 : 1.0

			// title
			let f_attrs: [NSAttributedString.Key: Any] = [ 	.font: NSFont.boldSystemFont(ofSize: 13.0),
																					.foregroundColor: itemColor,
																					.baselineOffset: 1.0]
	
			let title = (item.pinned ? "📌" : "") + (item.title/*?.th_displayTitle(maxLength: maxWidth, attrs: itemTitleAttrs, truncate: .byTruncatingTail)*/ ?? "--")
			let mi_title = NSMutableAttributedString(string: title, attributes: f_attrs)

			if let text = item.content/*?.th_displayTitle(maxLength: maxWidth, attrs: itemTitleAttrs, truncate: .byTruncatingTail) */{
				let attrs: [NSAttributedString.Key: Any] = [ 	.font: NSFont.systemFont(ofSize: 13.0),
																					.foregroundColor: itemColor,
																					.baselineOffset: 2.0]
				mi_title.append(NSAttributedString(string: "\n\(text)", attributes: attrs))
			}
			textField!.attributedStringValue = mi_title
		
			// info
			var pubDate: String?
			if let published = item.published {
				if Calendar.current.isDateInToday(published) == true {
					pubDate = Self.ago_df.localizedString(for: published, relativeTo: Date())
				}
				if pubDate == nil {
					pubDate = Self.todat_df.string(from: published, otherFormatter: Self.pub_df)
				}
			}
		
			var info = "\(channel.url.th_reducedHost) • \(pubDate ?? "nil")"

			if let published = item.published, let updated = item.updated, published != updated {
				let updated = Self.todat_df.string(from: updated, otherFormatter: Self.pub_df)
				info += ", updated: \(updated)"
			}

			infoLabel.textColor = itemColor
			infoLabel.stringValue = info

		}
		else if object.kind == 2 {
			textField!.objectValue = nil
			textField!.textColor = .red
		}
	
	}
	
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------
