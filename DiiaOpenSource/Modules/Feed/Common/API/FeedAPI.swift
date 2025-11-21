
import Foundation
import DiiaNetwork
import DiiaCommonServices

enum FeedAPI: CommonService {
    
    case getFeed
    case getNewsScreen
    case getNews(pagination: PaginationModel, type: String?)
    case getNewsDetails(id: String)
    case getEnemyTrackingLink
    
    var method: HTTPMethod {
        switch self {
        case .getFeed,
             .getNewsScreen,
             .getNews,
             .getNewsDetails,
             .getEnemyTrackingLink:
            return .get
        }
    }
    
    var path: String {
        switch self {
        case .getFeed:
            return "v1/feed"
        case .getNewsScreen:
            return "v1/feed/news/screen"
        case .getNews:
            return "v1/feed/news"
        case .getNewsDetails(let id):
            return "v1/feed/news/\(id)"
        case .getEnemyTrackingLink:
            return "v1/public-service/enemy-track/link"
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .getFeed,
             .getNewsScreen,
             .getNewsDetails,
             .getEnemyTrackingLink:
            return nil
        case .getNews(let pagination, let type):
            var dict = pagination.dictionary
            if let type {
                dict?.merge(dict: ["type": type])
            }
            return dict
        }
    }
    
    var analyticsName: String { return "" }
}
