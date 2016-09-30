import UIKit

class TradeItAccountManagementTableViewCell: UITableViewCell {

    @IBOutlet weak var accountNameLabel: UILabel!
    @IBOutlet weak var buyingPowerLabel: UILabel!
    @IBOutlet weak var accountEnabledSwitch: UISwitch!
    var selectedBrokerAccount: TradeItLinkedBrokerAccount!
    
    func populate(linkedBrokerAccount: TradeItLinkedBrokerAccount) {
        self.selectedBrokerAccount = linkedBrokerAccount
        self.accountEnabledSwitch.on = self.selectedBrokerAccount.isEnabled
        self.accountNameLabel.text = linkedBrokerAccount.getFormattedAccountName()
        self.buyingPowerLabel.text = linkedBrokerAccount.getFormattedBuyingPower()
    }
    
    //MARK: IBAction
    @IBAction func accountEnabledSwitchWasTapped(sender: AnyObject) {
        self.selectedBrokerAccount.isEnabled =  accountEnabledSwitch.on
    }
}