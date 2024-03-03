//
//  NftService.swift
//  FakeNFT
//
//  Created by Uliana Lukash on 21.02.2024.
//

import Foundation

final class NftService: RequestService {

    // MARK: - Public Properties

    static let shared = NftService()
    static let didGetNftNotification = Notification.Name(rawValue: "Did fetch NFT")
    static let didChangeNftsNotification = Notification.Name(rawValue: "Did fetch NFTs")
    // MARK: - Private Properties

    private (set) var nft: Nft?
    private (set) var nfts: [Nft] = []
    private var task: URLSessionTask?
    private var lastLoadedPage: Int?
    private let defaults = UserDefaults.standard

    // MARK: - Public Methods

    // MARK: - Public Methods
    func fetchNftsNextPage() {
                
        let nextPage = lastLoadedPage == nil
        ? 1
        : lastLoadedPage! + 1
        lastLoadedPage = nextPage
        
        guard let request = makeGetRequest(path: RequestConstants.fetchNfts(forPage: nextPage)) else {
            return assertionFailure("Не удалось создать запрос nfts")}
        let task = urlSession.objectTask(for: request) {[weak self] (result: Result<[Nft], Error>) in
            guard let self = self else { return }
            switch result {
            case .success(let nfts):
                self.nfts.append(contentsOf: nfts)
                NotificationCenter.default.post(name: NftService.didChangeNftsNotification, object: self, userInfo: ["nfts": self.nfts] )
            case .failure(let error):
                print(error)
            }
            self.task = nil
        }
        self.task = task
        task.resume()
    }
    
    func fetchNft(withId id: String) {

        guard let request = makeGetRequest(path: RequestConstants.fetchNft(withId: id)) else {
            return assertionFailure("Failed to make an NFT request")}

        let task = urlSession.objectTask(for: request) {[weak self] (result: Result<Nft, Error>) in
            guard let self = self else { return }
            switch result {
            case .success(let nft):
                self.nft = nft
                NotificationCenter.default.post(
                    name: NftService.didGetNftNotification,
                    object: self,
                    userInfo: ["nft": self.nft as Any] )
            case .failure(let error):
                print(error)
            }
            self.task = nil
        }
        self.task = task
        task.resume()
    }

    func clearData() {
        self.nfts = []
    }

    // MARK: - Private Methods
    
}
