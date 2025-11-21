
import ReactiveKit
import DiiaNetwork
import DiiaCommonTypes
import DiiaUIComponents
import DiiaCommonServices

protocol FeedAPIClientProtocol {
    func getFeedScreen() -> Signal<DSConstructorModel, NetworkError>
    func getFeedNewsScreen() -> Signal<DSConstructorModel, NetworkError>
    func getFeedNews(pagination: PaginationModel, type: String?) -> Signal<TemplatedResponse<FeedNewsResponse>, NetworkError>
    func getNewsDetails(id: String) -> Signal<DSConstructorModel, NetworkError>
    func getEnemyTrackingLink() -> Signal<LinkResponse, NetworkError>
}

class FeedAPIClient: ApiClient<FeedAPI>, FeedAPIClientProtocol {
    func getFeedScreen() -> Signal<DSConstructorModel, NetworkError> {
        return request(.getFeed)
    }
    
    func getFeedNewsScreen() -> Signal<DSConstructorModel, NetworkError> {
        return request(.getNewsScreen)
    }
    
    func getFeedNews(pagination: PaginationModel, type: String?) -> Signal<TemplatedResponse<FeedNewsResponse>, NetworkError> {
        return request(.getNews(pagination: pagination, type: type))
    }
    
    func getNewsDetails(id: String) -> Signal<DSConstructorModel, NetworkError> {
        return request(.getNewsDetails(id: id))
    }
    
    func getEnemyTrackingLink() -> Signal<LinkResponse, NetworkError> {
        return request(.getEnemyTrackingLink)
    }
}

