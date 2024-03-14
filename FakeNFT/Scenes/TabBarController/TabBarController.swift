import UIKit

final class TabBarController: UITabBarController {
    
    var servicesAssembly: ServicesAssembly?

    private let profileTabBarItem = UITabBarItem(
        title: NSLocalizedString(ConstLocalizable.tabProfile, comment: ""),
        image: UIImage(named: "profilActive"),
        tag: 0
    )

    private let statisticsTabBarItem = UITabBarItem(
        title: NSLocalizedString("Tab.statistics", comment: ""),
        image: UIImage(named: "statisticsTabBarItem"),
        tag: 0
    )
    
    private let catalogTabBarItem = UITabBarItem(
        title: NSLocalizedString("Tab.catalog", comment: ""),
        image: UIImage(systemName: "square.stack.fill"),
        tag: 1
    )
    
    private let basketTabBarItem = UITabBarItem(
        title: ConstLocalizable.basket,
        image: UIImage(named: "BasketNoActive"),
        tag: 2
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let profileController = createProfileController()
        let catalogController = createCatalogController()
        let basketController = createBasketViewController()
        let statsController = createStatsController()
        
        viewControllers = [profileController, catalogController, basketController, statsController]
        
        view.backgroundColor = .systemBackground
    }
    
    init(servicesAssembly: ServicesAssembly!) {
        self.servicesAssembly = servicesAssembly
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
    }
    
    private func createProfileController() -> UINavigationController {
        let profileViewModel = ProfileViewModel(service: ProfileServiceImpl(networkClient: DefaultNetworkClient(),
                                                                     storage: ProfileStorageImpl()))
        let profileController = ProfileViewController(viewModel: profileViewModel)
        
        profileController.tabBarItem = profileTabBarItem
        
        return UINavigationController(rootViewController: profileController)
    }
    
    private func createBasketViewController() -> UINavigationController {
        
        let basketViewModel = BasketViewModel(
            service: BasketService(
                networkClient: DefaultNetworkClient()
            ),
            storage: StorageManager()
        )
        
        let paymentViewModel = PaymentViewModel(
            service: PaymentService(
                networkClient: DefaultNetworkClient()
            )
        )
        let basketController = BasketViewController(viewModel: basketViewModel, paymentViewModel: paymentViewModel)
        basketController.tabBarItem = basketTabBarItem
        return UINavigationController(rootViewController: basketController)
    }

    private func createCatalogController() -> UINavigationController {
        
        let catalogViewModel = CatalogViewModel(
                service: CollectionServiceImpl(networkClient: DefaultNetworkClient(),
                storage: CollectionStorageImpl()))
        let rootController = CatalogViewController(viewModel: catalogViewModel)
        let catalogController = UINavigationController(rootViewController: rootController)
        catalogController.modalPresentationStyle = .fullScreen
        catalogController.tabBarItem = catalogTabBarItem
        return catalogController
    }
    
    private func createStatsController() -> UINavigationController {
        let userModel = RatingModel()
        guard let servicesAssembly else { return UINavigationController() }
        let ratingViewModel = RatingViewModel(for: userModel, servicesAssembly: servicesAssembly)
        let ratingViewController = UINavigationController(
            rootViewController: RatingViewController(
                viewModel: ratingViewModel
            )
        )
        ratingViewController.tabBarItem = statisticsTabBarItem
        
        return ratingViewController
    }
}
