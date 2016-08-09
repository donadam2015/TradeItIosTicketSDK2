import Quick
import Nimble

class TradeItSelectBrokerViewControllerSpec: QuickSpec {
    override func spec() {
        var controller: TradeItSelectBrokerViewController!
        var window: UIWindow!
        var nav: UINavigationController!
        var tradeItConnector: FakeTradeItConnector!

        describe("initialization") {
            beforeEach {
                tradeItConnector = FakeTradeItConnector()
                TradeItLauncher.tradeItConnector = tradeItConnector
                window = UIWindow()
                let bundle = NSBundle(identifier: "TradeIt.TradeItIosTicketSDK2Tests")
                let storyboard: UIStoryboard = UIStoryboard(name: "TradeIt", bundle: bundle)

                controller = storyboard.instantiateViewControllerWithIdentifier("TRADE_IT_SELECT_BROKER_VIEW") as! TradeItSelectBrokerViewController

                nav = UINavigationController(rootViewController: controller)
                
                expect(controller.view).toNot(beNil())
                expect(nav.view).toNot(beNil())
                
                window.addSubview(nav.view)
                NSRunLoop.currentRunLoop().runUntilDate(NSDate())
            }

            it("fetches the available brokers") {
                expect(tradeItConnector.calls.forMethod("getAvailableBrokersAsObjectsWithCompletionBlock").count).to(equal(1))
            }

            it("shows a spinner") {
                expect(controller.activityIndicator.isAnimating()).to(beTrue())
            }

            context("when request to get brokers fails") {
                beforeEach {
                    let completionHandler = tradeItConnector.calls.forMethod("getAvailableBrokersAsObjectsWithCompletionBlock")[0].args[0] as! (([TradeItBroker]?) -> Void)
                    completionHandler(nil)
                }

                it("hides the spinner") {
                    expect(controller.activityIndicator.isAnimating()).to(beFalse())
                }

                it("leaves the broker table empty") {
                    let brokerRowCount = controller.tableView(controller.brokerTable, numberOfRowsInSection: 0)
                    expect(brokerRowCount).to(equal(0))
                }

                it("shows an error alert") {
                    expect(controller.presentedViewController).toEventually(beAnInstanceOf(UIAlertController))
                    expect(controller.presentedViewController?.title).to(equal("Could not fetch brokers"))
                }
            }

            context("when request to get brokers succeeds") {
                beforeEach {
                    let broker1 = TradeItBroker(shortName: "Broker Short #1", longName: "Broker Long #1")
                    let broker2 = TradeItBroker(shortName: "Broker Short #2", longName: "Broker Long #2")
                    let brokersResponse = [broker1!, broker2!]

                    let completionHandler = tradeItConnector.calls.forMethod("getAvailableBrokersAsObjectsWithCompletionBlock")[0].args[0] as! (([TradeItBroker]?) -> Void)
                    completionHandler(brokersResponse)
                }

                it("hides the spinner") {
                    expect(controller.activityIndicator.isAnimating()).to(beFalse())
                }

                it("populates the broker table") {
                    let brokerRowCount = controller.tableView(controller.brokerTable, numberOfRowsInSection: 0)
                    expect(brokerRowCount).to(equal(2))

                    var cell = controller.tableView(controller.brokerTable,
                                                          cellForRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))

                    expect(cell.textLabel?.text).to(equal("Broker Long #1"))

                    cell = controller.tableView(controller.brokerTable,
                                                cellForRowAtIndexPath: NSIndexPath(forRow: 1, inSection: 0))

                    expect(cell.textLabel?.text).to(equal("Broker Long #2"))
                }

                describe("choosing a broker") {
                    beforeEach {
                        controller.tableView(controller.brokerTable, didSelectRowAtIndexPath: NSIndexPath(forRow: 1, inSection: 0))
                    }

                    it("goes to the login controller") {
                        let loginController = nav.topViewController as! TradeItLoginViewController
                        expect(loginController.title).to(equal("Login"))

                        let selectedBroker = loginController.selectedBroker
                        expect(selectedBroker?.brokerShortName).to(equal("Broker Short #2"))
                        expect(selectedBroker?.brokerLongName).to(equal("Broker Long #2"))
                    }
                }
            }
        }
    }
}