import UIKit

class TradeItAccountSelectionTableViewHeader: UITableViewCell {
    @IBOutlet weak var brokerLabel: UILabel!

    override func awakeFromNib() {
        self.backgroundColor = TradeItTheme.tableHeaderBackgroundColor
        self.brokerLabel.textColor = TradeItTheme.tableHeaderTextColor
    }
    
    func populate(withLinkedBroker linkedBroker: TradeItLinkedBroker) {
        self.brokerLabel.text = linkedBroker.linkedLogin.broker
    }
}
