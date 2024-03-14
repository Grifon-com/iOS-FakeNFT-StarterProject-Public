//
//  Router.swift
//  FakeNFT
//
//  Created by Григорий Машук on 1.03.24.
//

import UIKit

final class Router: BaseRouter {
    func showMyNft(profile: Profile) {
        guard let sourceVc = sourceViewController as? ProfileViewController
        else { return }
        let service = MyNFTServiceIml(networkClient: DefaultNetworkClient(),
                                      storage: MyNftStorageImpl())
        let viewModel = MyNftViewModel(service: service)
        let vc = MyNFTViewController(viewModel: viewModel)
        vc.delegate = sourceVc
        sourceVc.myNftDelegate = vc
        let navVc = UINavigationController(rootViewController: vc)
        navVc.modalPresentationStyle = .fullScreen
        sourceVc.myNftDelegate?.setProfile(model: profile, vc: sourceVc)
        sourceViewController?.present(navVc, animated: true)
    }
    
    func showFavarite() {
        let favoriteAssembly = FavoriteAssembly(
            service: FavoriteNftServiceImp(networkClient: DefaultNetworkClient()))
        guard let vc = favoriteAssembly.build() as? FavoriteViewController,
              let soursVc = sourceViewController as? ProfileViewController
        else { return }
        soursVc.favoriteDelegate = vc
        vc.delegate = soursVc
        let navVc = UINavigationController(rootViewController: vc)
        navVc.modalPresentationStyle = .fullScreen
        sourceViewController?.present(navVc, animated: true)
    }
    
    func showWebView(request: URLRequest) {
        guard let soursVc = sourceViewController else { return }
        let webViewController = ProfileWebViewController()
        webViewController.load(request: request)
        let navController = UINavigationController(rootViewController: webViewController)
        navController.modalPresentationStyle = .fullScreen
        webViewController.showIndicator()
        soursVc.present(navController, animated: true)
    }
}
