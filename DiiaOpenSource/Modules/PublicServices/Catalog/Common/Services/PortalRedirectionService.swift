
import UIKit
import ReactiveKit
import DiiaMVPModule
import DiiaNetwork
import DiiaUIComponents
import DiiaCommonServices
import DiiaCommonTypes

class PortalRedirectionService {
    private let apiClient: PublicServicesAPIClientProtocol
    private let disposeBag = DisposeBag()
    
    init(apiClient: PublicServicesAPIClientProtocol = PublicServicesAPIClient()) {
        self.apiClient = apiClient
    }
    
    func requestService(type: String, in view: BaseView) {
        view.showProgress()
        apiClient
            .getServiceTemplate(for: type)
            .observe { [weak self, weak view] (event) in
                guard let self, let view else { return }
                switch event {
                case .next(let response):
                    self.handleTemplate(alert: response.template, in: view)
                case .failed(let error):
                    GeneralErrorsHandler.process(
                        error: .init(networkError: error),
                        with: { [weak self] in
                            self?.requestService(type: type, in: view)
                        },
                        didRetry: false,
                        in: view)
                default:
                    return
                }
                view.hideProgress()
            }
            .dispose(in: disposeBag)
    }
    
    private func handleTemplate(alert: AlertTemplate, in view: BaseView) {
        TemplateHandler.handle(alert, in: view) { action in
            switch action {
            case Constants.webViewAction:
                guard let resource = alert.data.mainButton.resource else { return }
                _ = CommunicationHelper.url(urlString: resource)
            default: break
            }
        }
    }
}

private extension PortalRedirectionService {
    enum Constants {
        static let webViewAction = AlertTemplateAction("webView")
    }
}

struct PortalRedirectionRouter: RouterProtocol {
    let type: String
    let redirectionService: PortalRedirectionService
    
    func route(in view: BaseView) {
        redirectionService.requestService(type: type, in: view)
    }
}
