
import Foundation
import DiiaNetwork

enum PublicServicesAPI: CommonService {

    case getServices
    case getServiceTemplate(service: String)
    case getOnboarding(code: String)
    case finalScreen(service: String, code: String)
    
    var method: HTTPMethod {
        switch self {
        default:
            return .get
        }
    }
    
    var path: String {
        switch self {
        case .getServices:
            return "v3/public-service/catalog"
        case .getServiceTemplate(let service):
            return "v1/public-service/\(service)/portal"
        case .getOnboarding(let service):
            return "v1/public-service/\(service)/onboarding"
        case .finalScreen(let service, _):
            return "v1/public-service/\(service)/application/final-screen"
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .finalScreen(_, let code):
            return ["code": code]
        default: return nil
        }
    }

    var analyticsName: String {
        switch self {
        case .getServices:
            return Constants.getPublicServices
        case .getServiceTemplate:
            return Constants.getServiceTemplate
        case .getOnboarding(let service):
            return service + Constants.getOnboarding
        case .finalScreen(let service, _):
            return service + Constants.finalScreen
        }
    }
}

private extension PublicServicesAPI {
    enum Constants {
        static let getPublicServices = "getPublicServices"
        static let getServiceTemplate = "getServiceTemplate"
        static let getOnboarding = "GetOnboarding"
        static let finalScreen = "GetFinalScreen"
    }
}
