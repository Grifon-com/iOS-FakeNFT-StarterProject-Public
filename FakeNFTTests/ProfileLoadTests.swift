//
//  ProfileLoadTests.swift
//  FakeNFTTests
//
//  Created by Григорий Машук on 14.03.24.
//

@testable import FakeNFT
import XCTest

final class ProfileLoadTests: XCTestCase {
    func testSuccessLoading() throws {
        let service = ProfileServiceImpl(networkClient: StubNetworkClient(emulateError: false), storage: ProfileStorageImpl())
        
        let expectation = expectation(description: "Loading expectation")
        
        service.loadProfile { result in
            switch result {
            case .success(let profile):
                XCTAssertEqual(profile.nfts.count, 13)
                XCTAssertEqual(profile.likes.count, 12)
                expectation.fulfill()
            case .failure(_):
                XCTFail("Unexpected failure")
            }
        }
        
        waitForExpectations(timeout: 2)
    }
    
    func testFailureLoading() throws {
        let service = ProfileServiceImpl(networkClient: StubNetworkClient(emulateError: true), storage: ProfileStorageImpl())
        
        let expectation = expectation(description: "Loading expectation")
        
        service.loadProfile { result in
            switch result {
            case .success(_):
                XCTFail("Unexpected failure")
            case .failure(let error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2)
    }
}

struct StubNetworkClient: NetworkClient {
    enum TestError: Error {
        case test
    }
    
    let emulateError: Bool
    
    func send<T>(request: FakeNFT.NetworkRequest, type: T.Type, completionQueue: DispatchQueue, onResponse: @escaping (Result<T, Error>) -> Void) -> FakeNFT.NetworkTask? where T : Decodable {
        if emulateError {
            onResponse(.failure(TestError.test))
        } else {
            onResponse(.success(expectedModel as! T))
        }
        return nil
    }
    
    func send(request: FakeNFT.NetworkRequest, completionQueue: DispatchQueue, onResponse: @escaping (Result<Data, Error>) -> Void) -> FakeNFT.NetworkTask? {
        return nil
    }
    
    private var expectedModel: Decodable {
        Profile(name: "Студентус Практикумус",
                avatar: "https://code.s3.yandex.net/landings-v2-ios-developer/space.PNG",
                description: "Прошел 5-й спринт, и этот пройду",
                website: "https://practicum.yandex.ru/ios-developer",
                nfts: ["68","69","71","72","73","74","75","76","77","78","79","80","81"],
                likes: [ "5","13","19","26","27","33","35","39","41","47","56","66"],
                id: "1")
    }
}
