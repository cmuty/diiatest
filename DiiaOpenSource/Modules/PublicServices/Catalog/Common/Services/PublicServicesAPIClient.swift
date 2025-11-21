
import Foundation
import ReactiveKit
import DiiaNetwork
import DiiaCommonTypes
import DiiaUIComponents

protocol PublicServicesAPIClientProtocol {
    func getPublicServices() -> Signal<PublicServiceResponse, NetworkError>
    func getServiceTemplate(for service: String) -> Signal<AlertTemplateResponse, NetworkError>
    func getOnboarding(for type: String) -> Signal<DSConstructorModel, NetworkError>
    func getFinalScreen(publicService: String, code: String) -> Signal<DSConstructorModel, NetworkError>
}

class PublicServicesAPIClient: ApiClient<PublicServicesAPI>, PublicServicesAPIClientProtocol {

    public func getPublicServices() -> Signal<PublicServiceResponse, NetworkError> {
        return request(.getServices)
    }
    
    public func getServiceTemplate(for service: String) -> Signal<AlertTemplateResponse, NetworkError> {
        return request(.getServiceTemplate(service: service))
    }
    
    func getOnboarding(for type: String) -> Signal<DSConstructorModel, NetworkError> {
        return request(.getOnboarding(code: type))
    }
    
    func getFinalScreen(publicService: String, code: String) -> Signal<DSConstructorModel, NetworkError> {
        return request(.finalScreen(service: publicService, code: code))
    }
}
