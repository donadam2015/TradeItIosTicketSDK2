import UIKit

class TradeItBrokerManagementTableViewCell: UITableViewCell {
    @IBOutlet weak var brokerLabel: UILabel!
    @IBOutlet weak var brokerAccountsLabel: UILabel!

    override func awakeFromNib() {
        TradeItThemeConfigurator.configure(view: self)
    }

    func populate(withLinkedBroker linkedBroker: TradeItLinkedBroker) {
        let presenter = TradeItLinkedBrokerPresenter(linkedBroker: linkedBroker)
        self.brokerLabel.text = presenter.getFormattedBrokerLabel()
        self.brokerAccountsLabel.text = presenter.getFormattedBrokerAccountsLabel()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
