//  HeaderView.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class HeaderView: NSView, THOverViewDelegateProtocol {

	@IBOutlet var addMoreButtonView: THOverView!
	
	override func awakeFromNib() {
		super.awakeFromNib()

//		let isDark = THOSAppearance.isDarkMode()
//		self.bgColor = NSColor(calibratedWhite: 0.2, alpha: 1.0)

		self.menu = MoreMenu.shared.menu

		addMoreButtonView.repImage = NSImage(named: "NSSmartBadgeTemplate")//?.th_copyAndResize(NSSize()
	}
	
//	override func draw(_ dirtyRect: NSRect) {
//		NSColor(calibratedWhite: 0.8, alpha: 1.0).set()
//		NSBezierPath.fill(NSRect(0.0,0.0,self.bounds.size.width,1.0))
//	}
	
	// MARK: -
	
	func overView(_ sender: THOverView, drawRect rect: NSRect, withState state: THOverViewState) {
		if sender == addMoreButtonView {
			
//			let isDark = self.effectiveAppearance.name == .darkAqua

//			let color = isDark == true ?	(NSColor(calibratedWhite: state == .pressed ? 0.9 : state == .highlighted ? 0.8 : 1.0, alpha: 1.0)) :
//														(NSColor(calibratedWhite: state == .pressed ? 0.1 : state == .highlighted ? 0.2 : 0.0, alpha: 1.0))
//			let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 20), .foregroundColor: color]
//
//			sender.drawRepString(withAttrs: attrs, rect: rect, offSet: NSPoint(0.0, 1.0))
			sender.drawRepImage(opacity: state == .pressed ? 0.5 : state == .highlighted ? 1.0 : 0.9, centerdInRect: sender.bounds)
		}

	}
	
	func overView(_ sender: THOverView, didPressed withInfo: [String : Any]?) {
		if sender == addMoreButtonView {
			sender.popMenu(MoreMenu.shared.menu, isPull: true)
		}
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
