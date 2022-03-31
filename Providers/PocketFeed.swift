// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Storage

private let PocketEnvAPIKey = "PocketEnvironmentAPIKey"
private let PocketGlobalFeed = "https://getpocket.cdn.mozilla.net/v3/firefox/global-recs"
private let MaxCacheAge: Timestamp = OneMinuteInMilliseconds * 60 // 1 hour in milliseconds
private let SupportedLocales = ["en_CA", "en_US", "en_GB", "en_ZA", "de_DE", "de_AT", "de_CH"]
public let PocketVideoFeed = "https://getpocket.cdn.mozilla.net/v3/firefox/global-video-recs"

/*s
 The Pocket class is used to fetch stories from the Pocked API.
 Right now this only supports the global feed

 For a sample feed item check ClientTests/pocketglobalfeed.json
 */
struct PocketStory {
    let url: URL
    let title: String
    let storyDescription: String
    let imageURL: URL
    let domain: String

    static func parseJSON(list: Array<[String: Any]>) -> [PocketStory] {
        return list.compactMap({ (storyDict) -> PocketStory? in
            guard let urlS = storyDict["url"] as? String, let domain = storyDict["domain"] as? String,
                let imageURLS = storyDict["image_src"] as? String,
                let title = storyDict["title"] as? String,
                let description = storyDict["excerpt"] as? String else {
                    return nil
            }
            guard let url = URL(string: urlS), let imageURL = URL(string: imageURLS) else {
                return nil
            }
            return PocketStory(url: url, title: title, storyDescription: description, imageURL: imageURL, domain: domain)
        })
    }
}

private class PocketError: MaybeErrorType {
    var description = "Failed to load from API"
}

class Pocket {
    private let pocketGlobalFeed: String
    static let MoreStoriesURL = URL(string: "https://getpocket.com/explore?src=ff_ios&cdn=0")!

    // Allow endPoint to be overriden for testing
    init(endPoint: String = PocketGlobalFeed) {
        self.pocketGlobalFeed = endPoint
    }

    lazy fileprivate var urlSession = makeURLSession(userAgent: UserAgent.defaultClientUserAgent, configuration: URLSessionConfiguration.default)

    private func findCachedResponse(for request: URLRequest) -> [String: Any]? {
        let cachedResponse = URLCache.shared.cachedResponse(for: request)
        guard let cachedAtTime = cachedResponse?.userInfo?["cache-time"] as? Timestamp, (Date.now() - cachedAtTime) < MaxCacheAge else {
            return nil
        }

        guard let data = cachedResponse?.data, let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return nil
        }

        return json as? [String: Any]
    }

    private func cache(response: HTTPURLResponse?, for request: URLRequest, with data: Data?) {
        guard let resp = response, let data  = data else {
            return
        }
        let metadata = ["cache-time": Date.now()]
        let cachedResp = CachedURLResponse(response: resp, data: data, userInfo: metadata, storagePolicy: .allowed)
        URLCache.shared.removeCachedResponse(for: request)
        URLCache.shared.storeCachedResponse(cachedResp, for: request)
    }

    // Fetch items from the global pocket feed
    func globalFeed(items: Int = 2) -> Deferred<Array<PocketStory>> {
        let deferred = Deferred<Array<PocketStory>>()

        guard let request = createGlobalFeedRequest(items: items) else {
            deferred.fill([])
            return deferred
        }

        if let cachedResponse = findCachedResponse(for: request), let items = cachedResponse["recommendations"] as? Array<[String: Any]> {
            deferred.fill(PocketStory.parseJSON(list: items))
            return deferred
        }

        urlSession.dataTask(with: request) { (data, response, error) in
            guard let response = validatedHTTPResponse(response, contentType: "application/json"), let data = data else {
                return deferred.fill([])
            }

            self.cache(response: response, for: request, with: data)

            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            guard let items = json?["recommendations"] as? Array<[String: Any]> else {
                return deferred.fill([])
            }
            return deferred.fill(PocketStory.parseJSON(list: items))
        }.resume()

        return deferred
    }

    // Returns nil if the locale is not supported
    static func IslocaleSupported(_ locale: String) -> Bool {
        return false
    }

    // Create the URL request to query the Pocket API. The max items that the query can return is 20
    private func createGlobalFeedRequest(items: Int = 2) -> URLRequest? {
        guard items > 0 && items <= 20 else {
            return nil
        }

        let locale = Locale.current.identifier
        let pocketLocale = locale.replacingOccurrences(of: "_", with: "-")
        var params = [URLQueryItem(name: "count", value: String(items)), URLQueryItem(name: "locale_lang", value: pocketLocale), URLQueryItem(name: "version", value: "3")]
        if let _ = Bundle.main.object(forInfoDictionaryKey: PocketEnvAPIKey) as? String {
            params.append(URLQueryItem(name: "consumer_key", value: "69688-0187b8205b7a75b05d897e97"))
        }

        guard let feedURL = URL(string: pocketGlobalFeed)?.withQueryParams(params) else {
            return nil
        }

        return URLRequest(url: feedURL, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 5)
    }
}
