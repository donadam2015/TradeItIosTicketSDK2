import UIKit

class TradeItLinkBrokerUIFlow: NSObject,
                               TradeItWelcomeViewControllerDelegate,
                               TradeItSelectBrokerViewControllerDelegate,
                               TradeItLoginViewControllerDelegate {

    let viewControllerProvider: TradeItViewControllerProvider = TradeItViewControllerProvider()
    var onLinkedCallback: ((UINavigationController, _ linkedBroker: TradeItLinkedBroker) -> Void)?
    var onFlowAbortedCallback: ((UINavigationController) -> Void)?

    func presentLinkBrokerFlow(fromViewController viewController: UIViewController,
                                                  showWelcomeScreen: Bool,
                                                  onLinked: @escaping (_ presentedNavController: UINavigationController, _ linkedBroker: TradeItLinkedBroker) -> Void,
                                                  onFlowAborted: @escaping (_ presentedNavController: UINavigationController) -> Void) {
        self.onLinkedCallback = onLinked
        self.onFlowAbortedCallback = onFlowAborted

        let initialStoryboardId: TradeItStoryboardID = showWelcomeScreen ? .welcomeView : .selectBrokerView

        let navController = self.viewControllerProvider.provideNavigationController(withRootViewStoryboardId: initialStoryboardId)

        if let rootViewController = navController.viewControllers[0] as? TradeItWelcomeViewController {
            rootViewController.delegate = self
        } else if let rootViewController = navController.viewControllers[0] as? TradeItSelectBrokerViewController {
            rootViewController.delegate = self
        }
        
        viewController.present(navController, animated: true, completion: nil)
    }

    func presentRelinkBrokerFlow(inViewController viewController: UIViewController,
                                                 linkedBroker: TradeItLinkedBroker,
                                                 onLinked: @escaping (_ presentedNavController: UINavigationController, _ linkedBroker: TradeItLinkedBroker) -> Void,
                                                 onFlowAborted: @escaping (_ presentedNavController: UINavigationController) -> Void) {
        self.onLinkedCallback = onLinked
        self.onFlowAbortedCallback = onFlowAborted
        
        let navController = self.viewControllerProvider.provideNavigationController(withRootViewStoryboardId: TradeItStoryboardID.loginView)
        
        if let rootViewController = navController.viewControllers[0] as? TradeItLoginViewController {
            rootViewController.delegate = self
            rootViewController.selectedBroker = TradeItBroker(shortName: linkedBroker.linkedLogin.broker,
                                                              longName: linkedBroker.linkedLogin.broker) // TODO: Don't have longName here, not sure what to do...
            rootViewController.linkedBrokerToRelink = linkedBroker
        }
        
        viewController.present(navController, animated: true, completion: nil)
    }
    
    // MARK: TradeItWelcomeViewControllerDelegate

    func getStartedButtonWasTapped(_ fromWelcomeViewController: TradeItWelcomeViewController) {
        let selectBrokerViewController = self.viewControllerProvider.provideViewController(forStoryboardId: TradeItStoryboardID.selectBrokerView) as! TradeItSelectBrokerViewController

        selectBrokerViewController.delegate = self
        fromWelcomeViewController.navigationController!.pushViewController(selectBrokerViewController, animated: true)
//        fromWelcomeViewController.navigationController!.setViewControllers([selectBrokerViewController], animated: true)
    }

    func cancelWasTapped(fromWelcomeViewController welcomeViewController: TradeItWelcomeViewController) {
        self.onFlowAbortedCallback?(welcomeViewController.navigationController!)
    }

    // MARK: TradeItSelectBrokerViewControllerDelegate

    func brokerWasSelected(_ fromSelectBrokerViewController: TradeItSelectBrokerViewController, broker: TradeItBroker) {
        let loginViewController = self.viewControllerProvider.provideViewController(forStoryboardId: TradeItStoryboardID.loginView) as! TradeItLoginViewController
        loginViewController.delegate = self
        loginViewController.selectedBroker = broker
        fromSelectBrokerViewController.navigationController!.pushViewController(loginViewController, animated: true)
    }

    func cancelWasTapped(fromSelectBrokerViewController selectBrokerViewController: TradeItSelectBrokerViewController) {
        self.onFlowAbortedCallback?(selectBrokerViewController.navigationController!)
    }

    // MARK: TradeItLoginViewControllerDelegate

    func brokerLinked(fromTradeItLoginViewController: TradeItLoginViewController,
                      withLinkedBroker linkedBroker: TradeItLinkedBroker) {
        self.onLinkedCallback?(fromTradeItLoginViewController.navigationController!, linkedBroker)
    }
}
