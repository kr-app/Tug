//  PreviewController.swift

import Cocoa
import WebKit

//--------------------------------------------------------------------------------------------------------------------------------------------
class PreviewContainerView: NSView {

	override func setFrameSize(_ newSize: NSSize) {
		super.setFrameSize(newSize)

		if let webView = self.subviews.first(where: { $0 is WKWebView }) {
			webView.frame.size = NSSize(newSize.width * 1.333, newSize.height * 1.333)
		}
	}
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
class PreviewController: PPPanePreviewController, WKNavigationDelegate {

	@IBOutlet var mErrorTitleLabel: NSTextField!
	@IBOutlet var mErrorTextLabel: NSTextField!
	
	private var reqUrl: URL?
	private var mWebView: WKWebView?
	private var mErrorView: NSView { get { mErrorTitleLabel.superview! } }
	
	override func loadView() {
		super.loadView()
		
		self.view.wantsLayer = true
		self.view.layer!.cornerRadius = 5.0
	
		mErrorView.isHidden = true
		createWebView()
	}

	deinit {
		THLogDebug("")
	}

	// MARK: -

	func showAtPoint(_ point: NSPoint, link: URL, onScreen screen: NSScreen?) {
		super.showWindow(at: point, on: screen)
		startLoad(url: link)
	}

	override func panePreviewControllerWillShow() {
		mWebView!.isHidden = false
	}

	override func panePreviewControllerWillHide() {
		stop()
	}

	override func panePreviewControllerDidHide() {
		stop()
		mWebView!.loadHTMLString("<html></html>", baseURL: nil)
		mWebView!.isHidden = true
	}

	// MARK: -
	
	private func createWebView() {
		let wConf = WKWebViewConfiguration()
		wConf.allowsAirPlayForMediaPlayback = false
		wConf.mediaTypesRequiringUserActionForPlayback = .all

		let webPreferences = wConf.preferences
		webPreferences.javaScriptCanOpenWindowsAutomatically = false
		webPreferences.minimumFontSize = 15.0
		webPreferences.isFraudulentWebsiteWarningEnabled = false

		let margin: CGFloat = 0.0
		let containerView = PreviewContainerView(frame: NSRect(	margin,
																										margin,
																										self.view.frame.width - (margin * 2.0),
																										self.view.frame.height - (margin * 2.0)))
		containerView.autoresizingMask = [.width, .height]
		containerView.scaleUnitSquare(to: NSSize(0.75, 0.75))

		let webView = WKWebView(	frame: NSRect(0.0, 0.0, containerView.frame.width * 1.333, containerView.frame.height * 1.333),
														configuration: wConf)
		webView.autoresizingMask = [.width, .height]
		webView.navigationDelegate = self
//		webView.allowsMagnification = true
//		webView.magnification = 1.25
	
		webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
		webView.addObserver(self, forKeyPath: "title", options: .new, context: nil)

		mWebView = webView

		containerView.addSubview(webView)
		self.view.addSubview(containerView)
	}

	// MARK: -
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath == "estimatedProgress" {
			let ep = mWebView?.estimatedProgress
			THLogDebug("estimatedProgress:\(ep)")
		}
		else if keyPath == "title" {
		}
	}

	// MARK: -
	
	private func startLoad(url: URL) {
		THLogInfo("url:\(url.absoluteString)")
		reqUrl = url
	
		if mWebView == nil {
			createWebView()
		}

		mWebView?.isHidden = false
		mWebView?.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 15.0))

		mErrorView.isHidden = true
	}
	
	private func stop() {
		mWebView?.stopLoading()
	}

	// MARK: -

//	func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
//		webWindowController = WebWindowController(windowNibName: "WebWindowController")
//		webWindowController!.delegator = self
//		return webWindowController!.present(withConfiguration: configuration)
//	}

	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//		THLogDebug("request:\(navigationAction.request.url)")

		decisionHandler(.allow)
		
/*		let url = navigationAction.request.url

		if let url = url?.absoluteString {
			if url == "about:blank" {
				return decisionHandler(.allow)
			}
		}
		
		guard let host = url?.host
		else {
			THLogError("cancelled host:\(url?.host) request:\(url?.absoluteString)")
			return decisionHandler(.cancel)
		}

		let s = THHostFilter.shared.status(forHost: host)
		if s == .accepted || s == .refused {
			return decisionHandler(s == .accepted ? .allow : .cancel)
		}

		let alert = NSAlert(withTitle: "accept host?", message: url?.host ?? "?", buttons: ["Yes", "No"])
		let rep = alert.runModal()
		let accepted = rep == .alertFirstButtonReturn

		THHostFilter.shared.setHost(host, accepted: accepted)

		if accepted == true {
			log(.warning, "allowed host:\(url?.host) request:\(url?.absoluteString)")
			return decisionHandler(.allow)
		}
		
		log(.warning, "cancelled host:\(url?.host) request:\(url?.absoluteString)")
		decisionHandler(.cancel)*/
	}

	func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
		decisionHandler(.allow)
	}

	func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
	}
	
	func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
	}
	
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		//THLogInfo(@"URL:%@",webView.URL);
		if webView.isLoading == true {
			return
		}
	}

	func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
		THLogError("url:\(webView.url) error:\(error)")
		
		if webView.isLoading == false {
			mWebView!.isHidden = true
			
			mErrorView.isHidden = false
			mErrorTitleLabel.stringValue = reqUrl?.th_reducedHost ?? ""
			mErrorTextLabel.stringValue = THLocalizedString("") + "\n" + error.localizedDescription
		}
	}
	
}
//--------------------------------------------------------------------------------------------------------------------------------------------
