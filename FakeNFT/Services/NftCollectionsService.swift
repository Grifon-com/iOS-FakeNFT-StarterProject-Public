//
//  NftCollectionsService.swift
//  FakeNFT
//
//  Created by Uliana Lukash on 12.02.2024.
//

import Foundation

final class NftCollectionsService {

    // MARK: - Public Properties

    static let shared = NftCollectionsService()
    static let didChangeNotification = Notification.Name(rawValue: "NftCollectionsServiceDidChange")
    static let didChangeUserNotification = Notification.Name(rawValue: "Did fetch user")
    static let didChangeNftNotification = Notification.Name(rawValue: "Did fetch nft")
    static let didChangeNftsNotification = Notification.Name(rawValue: "Did fetch nfts")

    // MARK: - Private Properties
    private (set) var collections: [NftCollection] = []
    private (set) var collection: NftCollection?
    private (set) var user: User?
    private (set) var nft: Nft?
    private (set) var nfts: [Nft] = []
    private var task: URLSessionTask?
    private let urlSession = URLSession.shared
    private let defaults = UserDefaults.standard

    // MARK: - Public Methods
    func fetchCollections() {

        assert(Thread.isMainThread)
        if task != nil { return }

        guard let request = makeRequest(path: RequestConstants.collectionsFetchEndpoint) else {
            return assertionFailure("Failed to make collections request")}
        let task = urlSession.objectTask(for: request) {[weak self] (result: Result<[NftCollectionResponse], Error>) in
            guard let self = self else { return }
            switch result {
            case .success(let collections):
                self.mapCollections(collections)
                NotificationCenter.default.post(
                    name: NftCollectionsService.didChangeNotification,
                    object: self,
                    userInfo: ["collections": self.collections] )
            case .failure(let error):
                print(error)
            }
            self.task = nil
        }
        self.task = task
        task.resume()
    }

    func fetchNfts() {

        assert(Thread.isMainThread)
        if task != nil { return }

        guard let request = makeRequest(path: RequestConstants.nftsFetchEndpoint) else {
            return assertionFailure("Failed to make nfts request")}
        let task = urlSession.objectTask(for: request) {[weak self] (result: Result<[NftResponse], Error>) in
            guard let self = self else { return }
            switch result {
            case .success(let nfts):
                self.mapNfts(nfts)
                NotificationCenter.default.post(
                    name: NftCollectionsService.didChangeNftsNotification,
                    object: self,
                    userInfo: ["nfts": self.nfts] )
            case .failure(let error):
                print(error)
            }
            self.task = nil
        }
        self.task = task
        task.resume()
    }

    func fetchCollection(withId id: String) {
        if task != nil { return }

        guard let request = makeRequest(path: RequestConstants.fetchCollection(withId: id)) else {
            return assertionFailure("Failed to make a collection request")}
        let task = urlSession.objectTask(for: request) {[weak self] (result: Result<NftCollectionResponse, Error>) in
            guard let self = self else { return }
            switch result {
            case .success(let collection):
                self.mapCollection(collection)
                NotificationCenter.default.post(
                    name: NftCollectionsService.didChangeNotification,
                    object: self,
                    userInfo: ["collection": self.collection as Any] )
            case .failure(let error):
                print(error)
            }
            self.task = nil
        }
        self.task = task
        task.resume()
    }

    func fetchUser(withId id: String) {
        assert(Thread.isMainThread)
//        if task != nil { return }

        guard let request = makeRequest(path: RequestConstants.fetchUser(withId: id)) else {
            return assertionFailure("Failed to make a user request")}
        let task = urlSession.objectTask(for: request) {[weak self] (result: Result<UserResponse, Error>) in
            guard let self = self else { return }
            switch result {
            case .success(let user):
                self.mapUser(user)
                NotificationCenter.default.post(
                    name: NftCollectionsService.didChangeUserNotification,
                    object: self,
                    userInfo: ["user": self.user as Any] )
            case .failure(let error):
                print(error)
            }
            self.task = nil
        }
        self.task = task
        task.resume()
    }

    func fetchNft(withId id: String) {
        assert(Thread.isMainThread)
//        if task != nil { return }

        guard let request = makeRequest(path: RequestConstants.fetchNft(withId: id)) else {
            return assertionFailure("Failed to make an nft request")}
        let task = urlSession.objectTask(for: request) {[weak self] (result: Result<NftResponse, Error>) in
            guard let self = self else { return }
            switch result {
            case .success(let nft):
                self.mapNft(nft)
                NotificationCenter.default.post(
                    name: NftCollectionsService.didChangeNftNotification,
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

    private func mapNft(_ nft: NftResponse) {
        self.nft = Nft(
            createdAt: nft.createdAt,
            name: nft.name,
            id: nft.id,
            images: nft.images,
            rating: nft.rating,
            description: nft.description,
            price: nft.price,
            author: nft.author)
    }
    private func mapNfts(_ nfts: [NftResponse]) {
        self.nfts = nfts.map { nft in
            return Nft(
                createdAt: nft.createdAt,
                name: nft.name,
                id: nft.id,
                images: nft.images,
                rating: nft.rating,
                description: nft.description,
                price: nft.price,
                author: nft.author)
        }
    }
    private func mapCollections(_ collections: [NftCollectionResponse]) {
        let cols = collections.map { item in
            return NftCollection(createdAt: item.createdAt, name: item.name, cover: item.cover, nfts: item.nfts, description: item.description, author: item.author, id: item.id)
        }
        if let shouldFilterByName = defaults.object(forKey: "ShouldFilterByName") {
            self.collections = cols.sorted(by: {$0.name < $1.name})
        } else {
            self.collections = cols.sorted(by: {$0.nfts.count > $1.nfts.count})
        }

    }

    private func mapCollection(_ collection: NftCollectionResponse) {
        self.collection = NftCollection(
            createdAt: collection.createdAt,
            name: collection.name,
            cover: collection.cover,
            nfts: collection.nfts,
            description: collection.description,
            author: collection.author,
            id: collection.id)

    }

    private func mapUser(_ user: UserResponse) {
        self.user = User(
            name: user.name,
            avatar: user.avatar,
            description: user.description,
            website: user.website,
            nfts: user.nfts,
            rating: user.rating,
            id: user.id)

    }

}

extension NftCollectionsService {

    private func makeRequest(path: String) -> URLRequest? {

        guard let baseURL = URL(string: RequestConstants.baseURL) else {
            assertionFailure("base url is nil")
            return nil
        }
        guard let url = URL(string: path, relativeTo: baseURL) else {
            assertionFailure("failed to assemble request url")
            return nil
        }

        var request = URLRequest(url: url)

        request.setValue("\(RequestConstants.token)", forHTTPHeaderField: "X-Practicum-Mobile-Token")
        return request
    }
}
