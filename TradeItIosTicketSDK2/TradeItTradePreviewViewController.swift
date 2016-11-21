import UIKit
import MBProgressHUD

@objc internal protocol PreviewCellData {}

internal class WarningCellData: PreviewCellData {
    let warning: String

    init(warning: String) {
        self.warning = warning
    }
}

internal class AcknowledgementCellData: PreviewCellData {
    let acknowledgement: String
    var isAcknowledged = false

    init(acknowledgement: String) {
        self.acknowledgement = acknowledgement
    }
}

internal class ValueCellData: PreviewCellData {
    let label: String
    let value: String

    init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}

class TradeItTradePreviewViewController: TradeItViewController, UITableViewDelegate, UITableViewDataSource, AcknowledgementDelegate {
    @IBOutlet weak var orderDetailsTable: UITableView!
    @IBOutlet weak var placeOrderButton: UIButton!

    var linkedBrokerAccount: TradeItLinkedBrokerAccount!
    var previewOrderResult: TradeItPreviewOrderResult?
    var placeOrderCallback: TradeItPlaceOrderHandlers?
    var previewCellData: [PreviewCellData] = []
    var acknowledgementCellData: [AcknowledgementCellData] = []
    var alertManager = TradeItAlertManager()

    weak var delegate: TradeItTradePreviewViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.linkedBrokerAccount == nil {
            assertionFailure("TradeItIosTicketSDK ERROR: TradeItTradingPreviewViewController loaded without setting linkedBrokerAccount.")
        }

        previewCellData = generatePreviewCellData()

        orderDetailsTable.dataSource = self
        orderDetailsTable.delegate = self
        updatePlaceOrderButtonStatus()
    }

    @IBAction func placeOrderTapped(_ sender: UIButton) {
        guard let placeOrderCallback = placeOrderCallback else {
            print("TradeIt SDK ERROR: placeOrderCallback not set!")
            return
        }

        let activityView = MBProgressHUD.showAdded(to: self.view, animated: true)
        activityView.label.text = "Placing Order"

        placeOrderCallback({ result in
            activityView.hide(animated: true)
            self.delegate?.orderSuccessfullyPlaced(onTradePreviewViewController: self, withPlaceOrderResult: result)
        }, { error in
            activityView.hide(animated: true)
            self.alertManager.showRelinkError(error,
                withLinkedBroker: self.linkedBrokerAccount.linkedBroker,
                onViewController: self,
                onFinished: {} // TODO: Retry?
            )
        })
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return previewCellData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellData = previewCellData[indexPath.row]

        switch cellData {
        case let warningCellData as WarningCellData:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PREVIEW_ORDER_WARNING_CELL_ID") as! TradeItPreviewOrderWarningTableViewCell
            cell.populate(withWarning: warningCellData.warning)
            return cell
        case let acknowledgementCellData as AcknowledgementCellData:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PREVIEW_ORDER_ACKNOWLEDGEMENT_CELL_ID") as! TradeItPreviewOrderAcknowledgementTableViewCell
            cell.populate(withCellData: acknowledgementCellData, andDelegate: self)
            return cell
        case let valueCellData as ValueCellData:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PREVIEW_ORDER_VALUE_CELL_ID") as! TradeItPreviewOrderValueTableViewCell
            cell.populate(withLabel: valueCellData.label, andValue: valueCellData.value)
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    // MARK: AcknowledgementDelegate

    func acknowledgementWasChanged() {
        updatePlaceOrderButtonStatus()
    }

    // MARK: Private

    private func updatePlaceOrderButtonStatus() {
        if allAcknowledgementsAccepted() {
            placeOrderButton.isEnabled = true
            placeOrderButton.alpha = 1.0
        } else {
            placeOrderButton.isEnabled = false
            placeOrderButton.alpha = 0.5
        }
    }

    private func allAcknowledgementsAccepted() -> Bool {
        return acknowledgementCellData.filter{ !$0.isAcknowledged }.count == 0
    }

    private func generatePreviewCellData() -> [PreviewCellData] {
        guard let linkedBrokerAccount = linkedBrokerAccount,
            let orderDetails = previewOrderResult?.orderDetails
            else { return [] }

        var cells: [PreviewCellData] = []

        cells += generateWarningCellData()

        acknowledgementCellData = generateAcknowledgementCellData()
        cells += acknowledgementCellData as [PreviewCellData]

        let orderDetailsPresenter = TradeItOrderDetailsPresenter(orderDetails: orderDetails)
        cells += [
            ValueCellData(label: "ACCOUNT", value: linkedBrokerAccount.getFormattedAccountName()),
            ValueCellData(label: "SYMBOL", value: orderDetails.orderSymbol),
            ValueCellData(label: "QUANTITY", value: NumberFormatter.formatQuantity(orderDetails.orderQuantity)),
            ValueCellData(label: "ACTION", value: orderDetailsPresenter.getOrderActionLabel()),
            ValueCellData(label: "PRICE", value: orderDetails.orderPrice),
            ValueCellData(label: "EXPIRATION", value: orderDetailsPresenter.getOrderExpirationLabel())
        ] as [PreviewCellData]

        if let longHoldings = orderDetails.longHoldings {
            cells.append(ValueCellData(label: "SHARES OWNED", value: NumberFormatter.formatQuantity(longHoldings)))
        }

        if let shortHoldings = orderDetails.shortHoldings {
            cells.append(ValueCellData(label: "SHARES HELD SHORT", value: NumberFormatter.formatQuantity(shortHoldings)))
        }

        if let buyingPower = orderDetails.buyingPower {
            cells.append(ValueCellData(label: "BUYING POWER", value: formatCurrency(buyingPower)))
        }

        if let estimatedOrderCommission = orderDetails.estimatedOrderCommission {
            cells.append(ValueCellData(label: "BROKER FEE", value: formatCurrency(estimatedOrderCommission)))
        }

        if let estimatedTotalValue = orderDetails.estimatedTotalValue {
            cells.append(ValueCellData(label: "ESTIMATED COST", value: formatCurrency(estimatedTotalValue)))
        }

        return cells
    }

    private func generateWarningCellData() -> [PreviewCellData] {
        guard let warnings = previewOrderResult?.warningsList as? [String] else { return [] }

        return warnings.map({ warning in
            return WarningCellData(warning: warning)
        })
    }

    private func generateAcknowledgementCellData() -> [AcknowledgementCellData] {
        guard let acknowledgements = previewOrderResult?.ackWarningsList as? [String] else { return [] }

        return acknowledgements.map({ acknowledgement in
            return AcknowledgementCellData(acknowledgement: acknowledgement)
        })
    }

    private func formatCurrency(_ value: NSNumber) -> String {
        return NumberFormatter.formatCurrency(value, currencyCode: TradeItPresenter.DEFAULT_CURRENCY_CODE)
    }
}

protocol TradeItTradePreviewViewControllerDelegate: class {
    func orderSuccessfullyPlaced(onTradePreviewViewController tradePreviewViewController: TradeItTradePreviewViewController,
                                 withPlaceOrderResult placeOrderResult: TradeItPlaceOrderResult)
}
