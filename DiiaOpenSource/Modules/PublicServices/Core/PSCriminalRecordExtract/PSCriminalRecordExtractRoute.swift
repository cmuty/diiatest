import Foundation
import DiiaCommonTypes
import DiiaMVPModule
import DiiaNetwork
import DiiaPublicServices
import DiiaCommonServices

extension NetworkingContext {
    static func create() -> NetworkingContext {
        .init(session: NetworkConfiguration.default.session,
              host: EnvironmentVars.apiHost,
              headers: ["App-Version": AppConstants.App.appVersion,
                        "Platform-Type": AppConstants.App.platform,
                        "Platform-Version": AppConstants.App.iOSVersion,
                        "mobile_uid": AppConstants.App.mobileUID,
                        "User-Agent": AppConstants.App.userAgent])
        
    }
}

extension PSCriminalRecordExtractConfiguration {
    static func create() -> PSCriminalRecordExtractConfiguration {
        .init(ratingServiceOpener: RatingServiceOpener.instance,
              networkingContext: .create(),
              urlOpener: URLOpenerImpl(),
              paymentManager: PaymentManager())
    }
}

struct PSCriminalRecordExtractRoute: RouterProtocol {
    private let contextMenuItems: [ContextMenuItem]
    
    init(contextMenuItems: [ContextMenuItem]) {
        self.contextMenuItems = contextMenuItems
    }
    
    func route(in view: BaseView) {
        let baseCMP = BaseContextMenuProvider(publicService: .criminalRecordCertificate, items: contextMenuItems)
        let config: PSCriminalRecordExtractConfiguration = .create()
        view.open(module: CriminalExtractMainModule(contextMenuProvider: baseCMP, config: config))
    }
}
