// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

struct QwantJuniorUrls {
    private static let host = "https://mobile-secure.qwantjunior.com"
    
    enum StaticPages: String {
        case warning = "/warning"
        case ip = "/ip"
        case searchEngine = "/warning-search-engine"
        case timeout = "/timeout"
        
        func toURL() -> URL {
            let locale = Bundle.main.preferredLocalizations.first ?? "en"
            return URL(string: "\(QwantJuniorUrls.host)/public/index\(rawValue)/\(locale)")!
        }
    }
    
    enum API: String {
        case domainBlocklist = "/blacklist/domains"
        case urlBlocklist = "/blacklist/urls"
        case domainRedirect = "/redirect/domains"
        case urlRedirect = "/redirect/urls"
        
        func toURL(usingHash: Bool = true) -> URL {
            let hash = usingHash ? "/hash" : "/"
            return URL(string: "\(QwantJuniorUrls.host)/api/qwant-junior-mobile\(rawValue)\(hash)")!
        }
        
        var cacheKey: String {
            switch self {
                case .domainBlocklist: return "db"
                case .urlBlocklist: return "ub"
                case .domainRedirect: return "dr"
                case .urlRedirect: return "ur"
            }
        }
    }
}

enum QwantJuniorSafety: Equatable {
    case isSafe
    case isIp
    case isSearchEngine
    case isBlocked
    case timedOut
    case keepGoing
    
    var associatedStaticPage: URL? {
        switch self {
            case .isIp: return QwantJuniorUrls.StaticPages.ip.toURL()
            case .isSearchEngine: return QwantJuniorUrls.StaticPages.searchEngine.toURL()
            case .isBlocked: return QwantJuniorUrls.StaticPages.warning.toURL()
            case .timedOut: return QwantJuniorUrls.StaticPages.timeout.toURL()
            case .keepGoing, .isSafe: return nil
        }
    }
}

class QwantJuniorPolicy {
    
    private var cache: [String: Bool]
    private var skipCheckingPolicy = false
    
    lazy var youtubeCookie: HTTPCookie = {
        return HTTPCookie(properties: [
            .domain: ".youtube.com",
            .path: "/",
            .name: "PREF",
            .value: "f2=8000000",
            .secure: "TRUE",
            .expires: NSDate(timeIntervalSinceNow: 604_800)
        ])!
    }()
    
    init() {
        cache = [:]
    }
    
    func startSkippingPolicyChecks() {
        skipCheckingPolicy = true
    }
    
    func stopSkippingPolicyChecks(delay: CGFloat = 0.3) {
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            self.skipCheckingPolicy = false
        }
    }
    
    func ensureSafety(_ url: URL, completionHandler: @escaping (QwantJuniorSafety) -> Void) {
        let group = DispatchGroup()
        var lastKnownStatus: QwantJuniorSafety = .keepGoing
        
        defer {
            completionHandler(lastKnownStatus)
        }
        
        let exitIfNeeded: ((QwantJuniorSafety) -> Void) = { response in
            lastKnownStatus = response
            group.leave()
        }
        
        group.enter()
        earlyExitCheck(baseUrl: url, completionHandler: exitIfNeeded)
        
        group.wait()
        guard lastKnownStatus == .keepGoing else { return }
        group.enter()
        ipCheck(baseUrl: url, completionHandler: exitIfNeeded)
        
        group.wait()
        guard lastKnownStatus == .keepGoing else { return }
        group.enter()
        searchEngineCheck(baseUrl: url, completionHandler: exitIfNeeded)
        
        group.wait()
        guard lastKnownStatus == .keepGoing else { return }
        group.enter()
        domainAndUrlCheck(baseUrl: url, domainCheck: .domainRedirect, urlCheck: .urlRedirect, completionHandler: exitIfNeeded)
        
        group.wait()
        guard lastKnownStatus == .keepGoing else { return }
        group.enter()
        domainAndUrlCheck(baseUrl: url, domainCheck: .domainBlocklist, urlCheck: .urlBlocklist, completionHandler: exitIfNeeded)
        
        group.wait()
        guard lastKnownStatus == .keepGoing else { return }
        lastKnownStatus = .isSafe
    }
    
    private func earlyExitCheck(baseUrl url: URL, completionHandler: @escaping (QwantJuniorSafety) -> Void) {
        let allowListedWebsites = url.isMapsUrl || url.isQwantJuniorUrl || url.isQwantHelpUrl || url.isQwantAboutUrl || skipCheckingPolicy
        completionHandler(allowListedWebsites ? .isSafe : .keepGoing)
    }
    
    private func ipCheck(baseUrl url: URL, completionHandler: @escaping (QwantJuniorSafety) -> Void) {
        let host = url.normalizedHost ?? ""
        
        var sin = sockaddr_in()
        var sin6 = sockaddr_in6()
        
        if host.withCString({ cstring in inet_pton(AF_INET6, cstring, &sin6.sin6_addr) }) == 1 ||
            host.withCString({ cstring in inet_pton(AF_INET, cstring, &sin.sin_addr) }) == 1 {
            completionHandler(.isIp)
        } else {
            completionHandler(.keepGoing)
        }
    }
    
    private func searchEngineCheck(baseUrl url: URL, completionHandler: @escaping (QwantJuniorSafety) -> Void) {
        let host = url.normalizedHost ?? ""
        
        let fixedDomainSearchEngine =
        ["sm.cn", "mail.ru", "translate.goog"]
            .map { $0.replacingOccurrences(of: ".", with: "\\.") }
            .map { "([a-zA-Z0-9-]+\\.)?" + $0 }
        
        let anyOtherSearchEngine =
        ["google", "qwant", "bing", "yahoo", "baidu", "yandex", "duckduckgo", "sogou", "ecosia", "naver", "coccoc",
         "petalsearch", "seznam", "so", "startpage", "daum", "ask", "exalead", "gigablast", "kelseek", "lycos",
         "mozbot", "v9", "sukoga", "swisscows", "search.brave", "search.lilo"]
            .map { $0.replacingOccurrences(of: ".", with: "\\.") }
            .map { "^([a-zA-Z0-9-]+\\.)?" + $0 + "(\\.[a-zA-Z0-9]+)+" }
        
        let matches = (fixedDomainSearchEngine + anyOtherSearchEngine)
            .compactMap { try? NSRegularExpression(pattern: $0) }
            .map { $0.matches(in: host, range: NSRange(host.startIndex..., in: host)).map { String(host[Range($0.range, in: host)!]) } }
            .reduce([], +)
        
        completionHandler(matches.isEmpty ? .keepGoing : .isSearchEngine)
    }
    
    func shouldInsertCookie(baseUrl url: URL) -> Bool {
        let host = url.normalizedHost ?? ""
        let isYoutube =
        ["youtube", "youtu.be"]
            .map { "([a-z0-9-]+\\.)?" + $0 + "([\\/:&\\?].*)?" }
            .compactMap { try? NSRegularExpression(pattern: $0) }
            .map { $0.matches(in: host, range: NSRange(host.startIndex..., in: host)).map { String(host[Range($0.range, in: host)!]) } }
            .reduce([], +)
        
        return !isYoutube.isEmpty
    }
    
    private func domainAndUrlCheck(baseUrl url: URL, domainCheck: QwantJuniorUrls.API, urlCheck: QwantJuniorUrls.API, completionHandler: @escaping (QwantJuniorSafety) -> Void) {
        let group = DispatchGroup()
        var safety = QwantJuniorSafety.keepGoing
        
        group.enter()
        doRequestIfNeeded(for: domainCheck, at: url, with: [url.reversedHost]) { result in
            if result != .keepGoing && safety == .keepGoing {
                safety = result
            }
            group.leave()
        }
        
        group.enter()
        doRequestIfNeeded(for: urlCheck, at: url, with: url.urlsWithReversedHost) { result in
            if result != .keepGoing && safety == .keepGoing {
                safety = result
            }
            group.leave()
        }
        
        group.wait()
        completionHandler(safety)
    }
    
    private func doRequestIfNeeded(for kind: QwantJuniorUrls.API, at url: URL, with input: [String], completionHandler: @escaping (QwantJuniorSafety) -> Void) {
        
        let input = input.map { $0.toMD5 }
        let cacheKeys = input.map { kind.cacheKey + "_" + $0 }
        
        let cachedValues = cacheKeys.compactMap { cache[$0] != nil ? cache[$0]! : nil }
        if cachedValues.count > 0 {
            completionHandler(cachedValues.contains(true) == true ? .isBlocked : .keepGoing)
            return
        }
        
        var request = URLRequest(url: kind.toURL(), timeoutInterval: 0.5)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var body: [String] = []
        for i in 0..<input.count {
            body.append("test\(i+1)=\(input[i])")
        }
        request.httpBody = body.joined(separator: "&").data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error as? NSError {
                completionHandler(error.code == CFNetworkErrors.cfurlErrorTimedOut.rawValue ? .timedOut : .isBlocked)
                return
            }
            
            guard let data = data, let json = try? JSONDecoder().decode(Response.self, from: data) else {
                completionHandler(.isBlocked)
                return
            }

            let result = [json.value1, json.value2, json.value3].contains(true) == true
            cacheKeys.forEach { self?.cache[$0] = result }
            
            completionHandler(result ? .isBlocked : .keepGoing)
        }.resume()
    }
    
}

struct Response: Codable {
    var value1: Bool
    var value2: Bool?
    var value3: Bool?
    
    enum CodingKeys: String, CodingKey {
        case value1 = "test1"
        case value2 = "test2"
        case value3 = "test3"
    }
}

private extension URL {
    
    var reversedHost: String {
        return self.normalizedHost?.split(separator: ".").reversed().joined(separator: ".") ?? ""
    }
    
    var urlsWithReversedHost: [String] {
        let full = self.absoluteString
            .replacingOccurrences(of: (self.scheme ?? ""), with: "")
            .replacingOccurrences(of: (self.normalizedHost ?? ""), with: self.reversedHost)
            .replacingOccurrences(of: "://", with: "")
        let normalized = self.normalizedHostAndPath?.replacingOccurrences(of: (self.normalizedHost ?? ""), with: self.reversedHost) ?? ""
        var urls = [full, normalized]
        
        if normalized.hasSuffix("/") {
            urls.append(String(normalized.dropLast()))
        } else {
            urls.append(normalized.appending("/"))
        }
        
        return urls
    }
    
    var urlWithReversedHost: String {
        return self.normalizedHostAndPath?.replacingOccurrences(of: (self.normalizedHost ?? ""), with: self.reversedHost) ?? ""
    }
}

import CryptoKit

private extension String {

    var toMD5: String {
        return Insecure.MD5.hash(data: self.data(using: .utf8)!).map { String(format: "%02hhx", $0) }.joined()
    }
}
