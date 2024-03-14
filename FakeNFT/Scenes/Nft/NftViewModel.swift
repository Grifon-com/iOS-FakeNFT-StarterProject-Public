//
//  NftViewModel.swift
//  FakeNFT
//
//  Created by Uliana Lukash on 04.03.2024.
//

import Foundation

protocol NftViewModelDelegateProtocol: AnyObject {
    func updateCollectionView(oldCount: Int, newCount: Int)
}
protocol NftViewModelProtocol: AnyObject {
    var delegate: (NftViewModelDelegateProtocol)? { get set }
    func loadNft(withId id: String)
    var currencies: [Currency]? { get }
    var nft: Nft? { get }
    var nfts: [Nft] { get }
    func isLiked(nft nftId: String) -> Bool
    func isInCart(nft nftId: String) -> Bool
    func didTapLikeFor(nft id: String)
    func didTapCartFor(nft id: String)
    func setStateLoading()
    func fetchMoreNfts()
}
final class NftViewModel: NftViewModelProtocol {

    @Observable<NftState> private(set) var state: NftState = .initial
    weak var delegate: NftViewModelDelegateProtocol?

    private let currencyService: CurrenciesService
    private let nftService: NftService
    private let profileService: ProfileService
    private let orderService: OrderService

    private(set) var profile: Profile?
    private(set) var order: Order?
    private(set) var nft: Nft?
    private(set) var nfts: [Nft] = []
    private(set) var currencies: [Currency]?
    private var likes: [String] = []
    private var cart: [String] = []

    init(currencyService: CurrenciesService, nftService: NftService, profileService: ProfileService, orderService: OrderService) {
        self.currencyService = currencyService
        self.nftService = nftService
        self.profileService = profileService
        self.orderService = orderService
    }

    func setStateLoading() {
        self.state = .loading
    }

    func loadNft(withId id: String) {
        nftService.loadNft(id: id) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let nft):
                    self.saveNft(nft)
                    self.loadOrder()
                    self.loadProfile()
                    self.loadCurrencies()
                    self.fetchMoreNfts()
                    self.state = .data(nft)
                case .failure(let error):
                    self.state = .failed(error)
                }
            }
        }
    }

    private func loadProfile() {
        profileService.loadProfile { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    self.saveProfile(profile)
                case .failure(let error):
                    self.state = .failed(error)
                }
            }
        }
    }

    private func loadOrder() {
        orderService.loadOrder { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let order):
                    self.saveOrder(order)
                    guard let nft = self.nft else { return }
                    self.state = .data(nft)
                case .failure(let error):
                    self.state = .failed(error)
                }
            }
        }
    }

    private func saveProfile(_ profile: Profile) {
        self.profile = profile
        self.likes = profile.likes
    }

    private func saveOrder(_ order: Order) {
        self.order = order
        self.cart = order.nfts
    }

    private func loadCurrencies() {
        currencyService.loadCurrencies {[weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let currencies):
                    self.saveCurrencies(currencies)
                    self.state = .update
                case .failure(let error):
                    self.state = .failed(error)
                }
            }
        }
    }

    private func saveCurrencies(_ currencies: [Currency]) {
        self.currencies = currencies
    }

    func isLiked(nft nftId: String) -> Bool {

        guard let profile = profile else { return false }
        return profile.likes.contains(nftId)
    }

    func isInCart(nft nftId: String) -> Bool {
        guard let order = order else { return false }
        return order.nfts.contains(nftId)
    }

    func didTapLikeFor(nft id: String) {

        if likes.contains(id) {
            likes = likes.filter { $0 != id}
        } else {
            likes.append(id)
        }
        profileService.updateProfile(likes: likes) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async { [self] in
                switch result {
                case .success(let profile):
                    self.saveProfile(profile)
                    guard let nft = self.nft else { return }
                    self.state = .data(nft)
                case .failure(let error):
                    self.state = .failed(error)
                }
            }
        }
    }

    func makeErrorModel(error: Error) -> ErrorModel {
        let message: String
        switch error {
        case is NetworkClientError:
            message = ConstLocalizable.errorNetwork
        default:
            message = ConstLocalizable.errorUnknown
        }
        let actionText = ConstLocalizable.errorRepeat
        return ErrorModel(message: message, actionText: actionText) { [weak self] in
            guard let self else { return }
            self.state = .loading
        }
    }

    func didTapCartFor(nft id: String) {
        if cart.contains(id) {
            cart = cart.filter { $0 != id}
        } else {
            cart.append(id)
        }
        orderService.updateOrder(nfts: cart) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async { [self] in
                switch result {
                case .success(let order):
                    self.saveOrder(order)
                    guard let nft = self.nft else { return }
                    self.state = .data(nft)
                case .failure(let error):
                    self.state = .failed(error)
                }
            }
        }
    }

    private func saveNft(_ nft: Nft) {
        self.nft = nft
    }

    func isLiked(nft nftId: String) -> Bool? {

        guard let profile = profile else { return false }
        return profile.likes.contains(nftId)
    }

    func isInCart(nft nftId: String) -> Bool? {
        guard let order = order else { return false }
        return order.nfts.contains(nftId)
    }

    func fetchMoreNfts() {
        nftService.loadNftsNextPage { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async { [self] in
                switch result {
                case .success(let nfts):
                    self.updateCollectionView(nfts)
                case .failure(let error):
                    self.state = .failed(error)
                }
            }
        }
    }
    private func updateCollectionView(_ newNfts: [Nft]) {

        let oldCount = nfts.count
        let newCount = nfts.count + 10
        self.nfts += newNfts
        delegate?.updateCollectionView(oldCount: oldCount, newCount: newCount)
    }
}
