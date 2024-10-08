//
//  NetworkManager.swift
//  kidsbook
//
//  Created by paytalab on 8/9/24.
//

import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

public protocol NetworkManagerProtocol {
    func fetchData<T: Decodable>(urlString: String, httpMethod: HTTPMethod, headers: [String: String]?) async -> Result<T,NetworkError>
}

public struct NetworkManager: NetworkManagerProtocol {
    private let session: URLSessionProtocol
    public init(session: URLSessionProtocol) {
        self.session = session
        
    }
    
    public func fetchData<T: Decodable>(urlString: String, httpMethod: HTTPMethod, headers: [String: String]?) async -> Result<T,NetworkError> {
        
        guard let url = URL(string: urlString) else {
            return .failure(NetworkError.urlError(urlString))
        }
        debugPrint("URL - \(url)")
        do {
            var request = URLRequest(url: url)
            request.httpMethod = httpMethod.rawValue
            headers?.forEach { request.addValue($1, forHTTPHeaderField: $0) }
            let (data, response) = try await session.data(for: request)
            guard let response =  response as? HTTPURLResponse else { return .failure(NetworkError.invalidResponse) }
            if 200..<400 ~= response.statusCode {
                do {
                    let decodedData = try JSONDecoder().decode(T.self, from: data)
                    return .success(decodedData)
                } catch let error {
                    debugPrint(error)
                    return .failure(NetworkError.failToDecode(error.localizedDescription))
                }
            } else {
                return .failure(.serverError(response.statusCode))
            }

        } catch let error {
            return .failure(NetworkError.requestFail(error))
        }
    }
}
