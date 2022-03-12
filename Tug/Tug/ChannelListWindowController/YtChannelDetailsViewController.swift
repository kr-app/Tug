//  YtChannelDetailsViewController.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class YtChannelDetailsViewController: NSViewController {

	@IBOutlet var onOff: NSSwitch!
	@IBOutlet var iconView: NSImageView!
	@IBOutlet var titleLabel: NSTextField!
	@IBOutlet var videoIdLabel: NSTextField!
	@IBOutlet var lastUpdateLabel: NSTextField!
	@IBOutlet var lastErrorLabel: NSTextField!

	private let todayDf = THTodayDateFormatter(todayFormat: "HMS", otherFormatter: DateFormatter(dateStyle: .medium, timeStyle: .medium))
	private var channel: YtChannel!

	// MARK: -

	override func viewDidLoad() {
        super.viewDidLoad()
    }

	func updateUI(_ channel: YtChannel) {
		self.channel = channel

		iconView.image = THWebIconLoader.shared.icon(forHost: channel.url?.host, startUpdate: true, allowsGeneric: true)
		titleLabel.objectValue = channel.title
		onOff.state = channel.disabled == true ? .off : .on

		videoIdLabel.objectValue = channel.videoId.identifier

		let lu = channel.lastUpdate
		lastUpdateLabel.stringValue = lu != nil ? todayDf.string(from: lu!) : "--"

		lastErrorLabel.stringValue = channel.lastError ?? "--"
	}

	// MARK: -

	@IBAction func onOffAction(_ sender: NSSwitch) {
		YtChannelManager.shared.setAttribute(disabled: sender.state == .off, channel: channel.identifier)
	}

	@IBAction func urlChangeAction(_ sender: NSTextField) {
//		let row = self.tableView.selectedRow
//		if row == -1 {
//			return
//		}
//
//		let object = objectList![row]
//		let kind = object["kind"] as! Int
//		let channel = object["channel"] as! Channel
//
//		let url = c_urLabel.stringValue.trimmingCharacters(in: .whitespaces)
//
//		guard	url.isEmpty == false,
//					let nUrl = URL(string: url),
//					nUrl.host != nil
//		else {
//			return
//		}
//
//		if kind == 2 {
//			RssChannelManager.shared.addChannel(url: nUrl, startUpdate: false)
//			channelOnCreation = nil
//			self.updateUI()
//
//			RssChannelManager.shared.updateChannel(channel.identifier, completion: {() in
//				self.updateUISelection()
//			})
//
//			return
//		}
//
//		RssChannelManager.shared.setAttribute(url: nUrl, channel: channel.identifier)
//
//		RssChannelManager.shared.updateChannel(channel.identifier, completion: {() in
//			self.updateUISelection()
//		})
	}

	@IBAction func cleanAction(_ sender: NSButton) {
//		let row = self.tableView.selectedRow
//		if row == -1 {
//			return
//		}
//
//		let object = objectList![row]
//		let channel = object["channel"] as! Channel
//
//		RssChannelManager.shared.clean(channel: channel.identifier)
//
//		RssChannelManager.shared.updateChannel(channel.identifier, completion: {() in
//			self.updateUISelection()
//		})
	}
}
//--------------------------------------------------------------------------------------------------------------------------------------------
