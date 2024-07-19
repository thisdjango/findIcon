//
//  SearchViewModel.swift
//  findIcon
//
//  Created by Diana Tsarkova on 04.07.2024.
//

import UIKit.UIImage
import CoreData

class SearchViewModel {

    var errorHandler: ((String) -> Void)?
    var tableViewModel = IconTableViewModel()

    private var errorToShow: String?
    private var page = 0
    private var searchText: String?

    private var currentSearchWorkItem: DispatchWorkItem?
    private var currentSearchDataTask: URLSessionDataTask?

    init() {
        tableViewModel.paginationHandler = { [weak self] in
            guard let searchText = self?.searchText else { return }
            self?.searchIcon(text: searchText, paging: true)
        }
    }

    deinit {
        clear()
    }

    func updateResults() {
        if let errorToShow = errorToShow {
            errorHandler?(errorToShow)
        }
        tableViewModel.updateHandler?()
    }

    func clear() {
        tableViewModel.iconModels.removeAll()
        errorToShow = nil
        currentSearchWorkItem?.cancel()
        currentSearchDataTask?.cancel()
        page = 0
    }

    func searchIcon(text: String, paging: Bool = false) {
        if paging {
            page += 1
        }
        if text != searchText && currentSearchWorkItem != nil { 
            // text changed, no need in old request
            currentSearchDataTask?.cancel()
            currentSearchWorkItem?.cancel()
        }
        searchText = text
        let requestsQueue = DispatchQueue(label: "com.findIcon.requests", qos: .userInitiated)
        let group = DispatchGroup()
        currentSearchWorkItem = DispatchWorkItem { [weak self, weak tableViewModel] in
            self?.currentSearchDataTask = self?.getIcons(text: text) { [weak self, weak tableViewModel] result in
                switch result {
                case .success(let success):
                    tableViewModel?.iconModels.append(contentsOf: success)
                    self?.errorToShow = nil
                case .failure(let failure):
                    self?.errorToShow = failure.localizedDescription
                }
                group.leave()
            }
        }
        guard let currentSearchWorkItem = currentSearchWorkItem else {
            return
        }
        group.enter()
        requestsQueue.async(execute: currentSearchWorkItem)
        group.notify(queue: .main, execute: { [weak self] in
            self?.currentSearchWorkItem = nil
            self?.currentSearchDataTask = nil
            self?.updateResults()
        })
    }

    @discardableResult
    func getIcons(text: String, completion: @escaping (Result<[IconModel], Error>) -> Void) -> URLSessionDataTask? {
        let cache = URLCache.shared
        guard let request = formRequest(text: text, completion: completion) else {
            return nil
        }
        if let data = cache.cachedResponse(for: request)?.data,
           let iconSearchResults = try? JSONDecoder().decode(IconSearchResults.self, from: data) {
            completion(Result.success(iconSearchResults.icons.map { $0.toIconModel() }))
            return nil
        }
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
                completion(Result.failure(error))
                return
            }

            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode
            else {
                print("No data")
                completion(Result.failure(URLError.badServerResponse as! Error))
                return
            }
            do {
                let iconSearchResults = try JSONDecoder().decode(IconSearchResults.self, from: data)
                let cachedData = CachedURLResponse(response: httpResponse, data: data)
                cache.storeCachedResponse(cachedData, for: request)
                completion(Result.success(iconSearchResults.icons.map { $0.toIconModel() }))
            } catch let decodingError as DecodingError {
                print("Error: can't parse")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print(jsonString)
                }
                print(decodingError)
                completion(Result.failure(decodingError))
            } catch {
                print("Unknown Error: can't parse")
                completion(Result.failure(error))
            }
        }
        task.resume()
        return task
    }

    func formRequest(text: String, completion: @escaping (Result<[IconModel], Error>) -> Void) -> URLRequest? {
        guard let url = URL(string: "https://api.iconfinder.com/v4/icons/search"),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            completion(Result.failure(URLError.badURL as! Error))
            return nil
        }
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "query", value: text),
            URLQueryItem(name: "count", value: "10"),
            URLQueryItem(name: "offset", value: "\(page * 10)"),
            URLQueryItem(name: "premium", value: "0"),
            URLQueryItem(name: "vector", value: "0"),
        ]
        components.queryItems = components.queryItems.map { $0 + queryItems } ?? queryItems
        guard let componentsUrl = components.url else {
            completion(Result.failure(URLError.badURL as! Error))
            return nil
        }
        var request = URLRequest(url: componentsUrl)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "Authorization": "Bearer ZsizyvuuwptYc7PY1KduTqDlSVKF7CecaLDYmneBy08vJSGoVlYD2IxkRKuQlDo9"
        ]
        return request
    }
}
