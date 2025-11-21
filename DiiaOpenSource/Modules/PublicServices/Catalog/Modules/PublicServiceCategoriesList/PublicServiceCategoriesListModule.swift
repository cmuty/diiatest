
import UIKit
import DiiaMVPModule
import DiiaUIComponents

final class PublicServiceCategoriesListModule: BaseModule {
    private let view: UIViewController
    private let presenter: PublicServiceCategoriesListPresenter?

    public init(context: PublicServicesCoreContext) {
        let view = PublicServiceCategoriesListViewController()
        let apiClient = PublicServicesAPIClient()
        let publicServiceOpener = PublicServiceOpener(apiClient: apiClient,
                                                      routeManager: context.publicServiceRouteManager)
        let model = PublicServiceCategoriesModel(publicServiceOpener: publicServiceOpener)
        let presenter = PublicServiceCategoriesListPresenter(view: view,
                                                             apiClient: apiClient,
                                                             model: model,
                                                             storage: context.storeHelper)
        view.presenter = presenter
        
        self.view = view
        self.presenter = presenter
    }

    public func viewController() -> UIViewController {
        return view
    }
}
