import UIKit
import NetworkExtension
import CupLink

class TableViewController: UITableViewController {
    var app = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet var connectedStatusLabel: UILabel!
    
    @IBOutlet var toggleTableView: UITableView!
    @IBOutlet var toggleLabel: UILabel!
    @IBOutlet var toggleConnect: UISwitch!
    
    @IBOutlet weak var statsSelfIPCell: UITableViewCell!
    @IBOutlet weak var statsSelfSubnetCell: UITableViewCell!
    @IBOutlet weak var statsSelfCoordsCell: UITableViewCell!
    
    @IBOutlet var statsSelfIP: UILabel!
    @IBOutlet var statsSelfSubnet: UILabel!
    @IBOutlet var statsSelfCoords: UILabel!
    @IBOutlet var statsSelfPeers: UILabel!
    
    @IBOutlet var statsVersion: UILabel!
    
    override func viewDidLoad() {      
        NotificationCenter.default.addObserver(self, selector: #selector(self.onCupLinkSelfUpdated), name: NSNotification.Name.CupLinkSelfUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onCupLinkPeersUpdated), name: NSNotification.Name.CupLinkPeersUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onCupLinkDHTUpdated), name: NSNotification.Name.CupLinkDHTUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onCupLinkSettingsUpdated), name: NSNotification.Name.CupLinkSettingsUpdated, object: nil)
    }
    
    @IBAction func onRefreshButton(_ sender: UIButton) {
        sender.isEnabled = false
        app.makeIPCRequests()
        sender.isEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //NotificationCenter.default.addObserver(self, selector: #selector(TableViewController.VPNStatusDidChange(_:)), name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
        
        if let row = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: row, animated: true)
        }
        
        self.statsVersion.text = CupLink.MobileGetVersion()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.onCupLinkSelfUpdated(notification: NSNotification.init(name: NSNotification.Name.CupLinkSettingsUpdated, object: nil))
    }
    
    override func viewWillLayoutSubviews() {
        self.onCupLinkSelfUpdated(notification: NSNotification.init(name: NSNotification.Name.CupLinkSettingsUpdated, object: nil))
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let row = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: row, animated: true)
        }
    }
    
    @objc func onCupLinkSettingsUpdated(notification: NSNotification) {
        toggleLabel.isEnabled = !app.vpnManager.isOnDemandEnabled
        toggleConnect.isEnabled = !app.vpnManager.isOnDemandEnabled
        
        if let footer = toggleTableView.footerView(forSection: 0) {
            if let label = footer.textLabel {
                label.text = app.vpnManager.isOnDemandEnabled ? "CupLink is configured to automatically start and stop based on available connectivity." : "CupLink is configured to start and stop manually."
            }
        }
    }
    
    func updateConnectedStatus() {
        if self.app.vpnManager.connection.status == .connected {
            if app.CupLinkDHT.count > 0 {
                connectedStatusLabel.text = "Enabled"
                connectedStatusLabel.textColor = UIColor(red: 0.37, green: 0.79, blue: 0.35, alpha: 1.0)
            } else {
                connectedStatusLabel.text = "No connectivity"
                connectedStatusLabel.textColor = UIColor.red
            }
        } else {
            connectedStatusLabel.text = "Not enabled"
            connectedStatusLabel.textColor = UIColor.systemGray
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func onCupLinkSelfUpdated(notification: NSNotification) {
        statsSelfIP.text = app.CupLinkSelfIP
        statsSelfSubnet.text = app.CupLinkSelfSubnet
        statsSelfCoords.text = app.CupLinkSelfCoords
        
        statsSelfIPCell.layoutSubviews()
        statsSelfSubnetCell.layoutSubviews()
        statsSelfCoordsCell.layoutSubviews()
        
        let status = self.app.vpnManager.connection.status
        toggleConnect.isOn = status == .connecting || status == .connected
        
        self.updateConnectedStatus()
    }
    
    @objc func onCupLinkDHTUpdated(notification: NSNotification) {
        self.updateConnectedStatus()
    }
    
    @objc func onCupLinkPeersUpdated(notification: NSNotification) {
        let peercount = app.CupLinkPeers.count
        if peercount <= 0 {
            statsSelfPeers.text = "No peers"
        } else if peercount == 1 {
            statsSelfPeers.text = "\(peercount) peer"
        } else {
            statsSelfPeers.text = "\(peercount) peers"
        }
    }

    @IBAction func toggleVPNStatus(_ sender: UISwitch, forEvent event: UIEvent) {
        if sender.isOn {
            do {
                try self.app.vpnManager.connection.startVPNTunnel()
            } catch {
                print(error)
            }
        } else {
            self.app.vpnManager.connection.stopVPNTunnel()
        }
    }
}
