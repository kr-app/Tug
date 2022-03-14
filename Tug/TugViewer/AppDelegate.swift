// AppDelegate.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
@main
class AppDelegate: NSObject, NSApplicationDelegate {

	private let parentAppAlive = THParentAppAlive(withParentAppIdentifier: "com.kr-app.com.Tug")
	private var previewController: PreviewController?

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		THLogInfo("config:\(THRunningApp.config())")

		DistributedNotificationCenter.default.addObserver(self,
																				selector: #selector(n_panePreviewRequest),
																				name: PPPaneRequester.requestNotificationName,
																				object: nil)
//#if DEBUG
//		perform(#selector(test), with: nil, afterDelay: 1.0)
//#endif

	}

	func applicationWillTerminate(_ aNotification: Notification) {
	}
	
	// MARK: -
	
#if DEBUG
	@objc private func test() {
		if TH_isDebuggerAttached() == false {
			return
		}
		
		let n = Notification(	name: PPPaneRequester.requestNotificationName,
										object: nil,
										userInfo: [	PPPaneRequesterKey.action: "show",
															PPPaneRequesterKey.point: NSStringFromPoint(NSPoint(600, 300)),
															PPPaneRequesterKey.data: "https://www.apple.com"])
		perform(#selector(n_panePreviewRequest), with: n, afterDelay: 1.0)

//		let n2 = Notification(	name: PPPaneRequester.requestNotificationName,
//										object: nil,
//										userInfo: [	PPPaneRequester.keyAction: "hide"])
//		perform(#selector(n_panePreviewRequest), with: n2, afterDelay: 5.0)
//
//		let n3 = Notification(	name: PPPaneRequester.requestNotificationName,
//										object: nil,
//										userInfo: [	PPPaneRequester.keyAction: "show",
//															PPPaneRequester.keyPoint: NSStringFromPoint(NSPoint(600, 300)),
//															PPPaneRequester.keyData: "http://www.microsoft.com"])
//		perform(#selector(n_panePreviewRequest), with: n3, afterDelay: 10.0)
	}
#endif

	// MARK: -
	
	@objc private func n_panePreviewRequest(_ notification: Notification) {
		THLogDebug("notification:\(notification)")

		guard let info = notification.userInfo
		else {
			return
		}

		let action = info[PPPaneRequesterKey.action] as? String

		if action == "show" {
			guard 	let point = info[PPPaneRequesterKey.point] as? String,
						let link = info[PPPaneRequesterKey.data] as? String,
						let screen = NSScreen.main
			else {
				THLogError("point | link | screen, notification:\(notification)")
				return
			}
	
			let parentPid = info[PPPaneRequesterKey.parentPid] as! pid_t
			parentAppAlive.update(withParentPid: parentPid)
	
			if previewController == nil {
				previewController = PreviewController(nibName: "PreviewController", bundle: nil)
				//previewController.delegate = self
			}

			previewController!.showAtPoint(NSPointFromString(point), link: URL(string: link)!, onScreen: screen)
		}
		else if action == "hide" {
			previewController?.hideWindow(animated: (info[PPPaneRequesterKey.animated] as? Bool) ?? true)
		}
		else if action == "close" {
			previewController?.hideWindow(animated: (info[PPPaneRequesterKey.animated] as? Bool) ?? true)
			NSApplication.shared.terminate(nil)
		}
	}
	
}
//--------------------------------------------------------------------------------------------------------------------------------------------
