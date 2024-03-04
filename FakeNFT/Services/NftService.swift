//
//  NftService.swift
//  FakeNFT
//
//  Created by Uliana Lukash on 21.02.2024.
//

import Foundation


typealias NftCompletion = (Result<Nft, Error>) -> Void
typealias NftsCompletion = (Result<[Nft], Error>) -> Void

protocol NftService {
    func loadNft(id: String, completion: @escaping NftCompletion)
    func loadNftsNextPage(completion: @escaping NftsCompletion)
    func loadNfts(withIds nfts: [String], completion: @escaping NftsCompletion)
}

final class NftServiceImpl: NftService {

    private var lastLoadedPage: Int?
    private let networkClient: NetworkClient
    private let storage: NftStorage

    init(networkClient: NetworkClient, storage: NftStorage) {
        self.storage = storage
        self.networkClient = networkClient
    }

    func loadNft(id: String, completion: @escaping NftCompletion) {
        if let nft = storage.getNft(with: id) {
            completion(.success(nft))
            return
        }

        let request = NFTRequest(id: id)
        networkClient.send(request: request, type: Nft.self) { [weak storage] result in
            switch result {
            case .success(let nft):
                storage?.saveNft(nft)
                completion(.success(nft))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func loadNftsNextPage(completion: @escaping NftsCompletion) {
        let nextPage = lastLoadedPage == nil
        ? 1
        : lastLoadedPage! + 1
        lastLoadedPage = nextPage

        let request = NFTsRequest(page: nextPage)

        networkClient.send(request: request, type: [Nft].self) { result in
            switch result {
            case .success(let nfts):
                completion(.success(nfts))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func loadNfts(withIds nfts: [String], completion: @escaping NftsCompletion) {
        var returnNfts: [Nft] = []

        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1

        for id in nfts {
            let operation = BlockOperation {
                let request = NFTRequest(id: id)
                var nft: Nft?

                let semaphore = DispatchSemaphore(value: 0)

                self.load(request: request) { result in
                    switch result {
                    case .success(let loadedNFT):
                        nft = loadedNFT
                    case .failure(let error):
                        completion(.failure(error))
                        return
                    }
                    semaphore.signal()
                }
                _ = semaphore.wait(timeout: .distantFuture)

                if let nft = nft {
                    returnNfts.append(nft)

                    if returnNfts.count == nfts.count {
                        completion(.success(returnNfts))
                    }
                }
            }
            operationQueue.addOperation(operation)
        }
    }

    func load(request: NetworkRequest,
              completion: @escaping NftCompletion) {
        networkClient.send(request: request,
                           type: Nft.self) { result in
            switch result {
            case .success(let nft):
                completion(.success(nft))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
