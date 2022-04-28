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

	private let todayDateFormatter = THTodayDateFormatter(todayFormat: "HMS", otherFormatter: DateFormatter(dateStyle: .medium, timeStyle: .medium))
	private var channel: YtChannel!

	// MARK: -

	override func viewDidLoad() {
        super.viewDidLoad()
    }

	func updateUI(_ channel: YtChannel) {
		self.channel = channel
		updateUI()
	}

	private func updateUI() {

		var icon: NSImage?
		if let poster = channel.poster {
			icon = THIconDownloader.shared.icon(atURL: poster, startUpdate: true)
		}

		iconView.image = icon ?? THFavIconLoader.shared.icon(forHost: channel.url?.host, startUpdate: true, allowsGeneric: true)
		titleLabel.objectValue = channel.title
		onOff.state = channel.disabled == true ? .off : .on

		videoIdLabel.objectValue = channel.videoId.identifier

		let lu = channel.lastUpdate
		lastUpdateLabel.stringValue = lu != nil ? todayDateFormatter.string(from: lu!) : "--"

		lastErrorLabel.stringValue = channel.lastError?.error ?? "--"
		lastErrorLabel.toolTip = channel.lastError?.date == nil ? nil : todayDateFormatter.string(from: channel.lastError!.date)
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
//			YtChannelManager.shared.addChannel(url: nUrl, startUpdate: false)
//			channelOnCreation = nil
//			self.updateUI()
//
//			YtChannelManager.shared.updateChannel(channel.identifier, completion: {() in
//				self.updateUISelection()
//			})
//
//			return
//		}
//
//		YtChannelManager.shared.setAttribute(url: nUrl, channel: channel.identifier)

		YtChannelManager.shared.updateChannel(channel, completion: {() in
			self.updateUI()
		})
	}

	@IBAction func cleanAction(_ sender: NSButton) {
		YtChannelManager.shared.updateChannel(channel, completion: {() in
			self.updateUI()
		})
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
