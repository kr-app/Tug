//  StatusIcon.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
extension NSStatusBarButton {

	public override func mouseDown(with event: NSEvent) {

//		if StatusIcon.ss == false {
//			super.mouseDown(with: event)
//			return
//		}

		if event.modifierFlags.contains(.control) {
			self.rightMouseDown(with: event)
			return
		}

		self.highlight(true)
		let _ = self.target?.perform(self.action, with: self)
	}

//	public override var isHighlighted: Bool { get {
//		return true
//	}
//	set { }
//	}

//	public override func highlight(_ flag: Bool) {
//		super.highlight(flag)
//	}

//	public override func rightMouseDown(with event: NSEvent) {
//		self.highlight(true)
//	}
	
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
class StatusIcon: NSObject {

	@objc var barItem: NSStatusItem!
	var statusItemWindow: NSWindow? { get { barItem.button!.window } }

	private let barIcon = NSImage(named: "tug_bar")!.th_copyAndResize(NSMakeSize(16.0, 16.0))!

	override init() {
		self.barItem = NSStatusBar.system.statusItem(withLength: -1)

//		Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer: Timer) in
//			//print("isHighlighted: \(self.barItem.button!.isHighlighted)")
//		})
	}
	
	func updateBadge() {
		let ref = RssChannelManager.shared.recentRefDate()
		let nbu = RssChannelManager.shared.hasWallChannels(withDateRef: ref, atLeast: 10)

		let transp = THOSAppearance.hasReduceTransparency()
		
		let icon = barIcon.th_tinted(withColor: nbu ? (transp == true ? .black : .white) : NSColor(calibratedWhite: 0.5, alpha: 1.0))
		
		barItem.button!.image = icon
		barItem.button!.alternateImage = barIcon.th_tinted(withColor: .white)
//		let c = barItem.button!.cell?.isHighlighted
//
//
//		print("")
	}
	
	func setIsPressed(_ pressed: Bool) {
		barItem.button?.highlight(pressed)
		
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
