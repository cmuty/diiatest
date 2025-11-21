
import UIKit
import DiiaMVPModule

final class FeedNewsModule: BaseModule {
    private let view: FeedNewsViewController
    private let presenter: FeedNewsPresenter
    
    init(type: String? = nil) {
        view = FeedNewsViewController()
        presenter = FeedNewsPresenter(view: view, type: type)
        view.presenter = presenter
    }

    func viewController() -> UIViewController {
        return view
    }
}
