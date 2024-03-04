//
//  ProfilePutRequest.swift
//  FakeNFT
//
//  Created by Uliana Lukash on 04.03.2024.
//

import Foundation

struct ProfilePutRequest: NetworkRequest {
    var httpMethod: HttpMethod { .put }

    var endpoint: URL? {
        URL(string: "\(RequestConstants.baseURL)/profile/1")
    }

    var dto: Encodable?
}
