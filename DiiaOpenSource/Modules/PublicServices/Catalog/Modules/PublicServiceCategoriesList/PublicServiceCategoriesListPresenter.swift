
import UIKit
import ReactiveKit
import DiiaMVPModule
import DiiaNetwork
import DiiaUIComponents
import DiiaCommonServices
import DiiaCommonTypes

class PublicServiceCategoriesModel {
    var allItems: [PublicServiceCategoryViewModel]
    var visibleItems: [PublicServiceCategoryViewModel]
    var currentTab: PublicServiceTabType?
    var publicServiceTabsViewModel: TabSwitcherViewModel
    let publicServiceOpener: PublicServiceOpenerProtocol
    var additionalObjects: [ServiceAdditionalElement]?
    
    init(allItems: [PublicServiceCategoryViewModel] = [],
         visibleItems: [PublicServiceCategoryViewModel] = [],
         currentTab: PublicServiceTabType? = nil,
         publicServiceTabsViewModel: TabSwitcherViewModel = .init(),
         publicServiceOpener: PublicServiceOpenerProtocol,
         additionalObjects: [ServiceAdditionalElement]? = nil) {
        self.allItems = allItems
        self.visibleItems = visibleItems
        self.currentTab = currentTab
        self.publicServiceTabsViewModel = publicServiceTabsViewModel
        self.publicServiceOpener = publicServiceOpener
        self.additionalObjects = additionalObjects
    }
}

protocol PublicServiceCategoriesListAction: BasePresenter, DSConsructorEventHandler {
    func numberOfItems(withChips: Bool) -> Int
    func getActiveSections() -> [PublicServiceSection]
    func itemAt(index: Int, withChip: Bool) -> PublicServiceCategoryViewModel?
    func itemSelected(index: Int, withChip: Bool)
    func updateServices()
    func checkReachability()
    func searchClick()
    func getTabsViewModel() -> TabSwitcherViewModel
    func getNewsData() -> DSHalvedCardCarouselModel?
}

final class PublicServiceCategoriesListPresenter: NSObject, PublicServiceCategoriesListAction {
    
    // MARK: - Properties
    unowned var view: PublicServiceCategoriesListView
    private let storage: PublicServicesStorage?
    private let apiClient: PublicServicesAPIClientProtocol
    private var model: PublicServiceCategoriesModel
    private let disposedBag = DisposeBag()
    
    // MARK: - Init
    init(view: PublicServiceCategoriesListView,
         apiClient: PublicServicesAPIClientProtocol,
         model: PublicServiceCategoriesModel,
         storage: PublicServicesStorage?) {
        self.view = view
        self.apiClient = apiClient
        self.model = model
        self.storage = storage
    }
    
    func configureView() {
        ReachabilityHelper.shared
            .statusSignal
            .observeNext { [weak self] isReachable in
                self?.onNetworkStatus(isReachable: isReachable)
            }
            .dispose(in: disposedBag)
    }

    private func onNetworkStatus(isReachable: Bool) {
        if isReachable && numberOfItems() == 0 {
            updateServices()
        }
    }

    // MARK: - PublicServiceCategoriesListAction
    
    func handleEvent(event: ConstructorItemEvent) {
        let actionModel = event.actionParameters()
        switch actionModel?.type {
        case Constants.newsAction:
            guard let id = actionModel?.resource else { return }
            view.open(module: FeedNewsDetailsModule(newsId: id))
        case Constants.allNews:
            view.open(module: FeedNewsModule(type: model.currentTab?.rawValue))
        default: log(actionModel?.type ?? .empty)
        }
    }
    
    func numberOfItems(withChips: Bool = false) -> Int {
        return getItems(hasChip: withChips).count
    }
    
    func itemAt(index: Int, withChip: Bool) -> PublicServiceCategoryViewModel? {
        let items = getItems(hasChip: withChip)
        if index >= 0 && index < items.count {
            return items[index]
        }
        return nil
    }
    
    func itemSelected(index: Int, withChip: Bool) {
        let items = getItems(hasChip: withChip)
        guard
            items.indices.contains(index)
        else {
            return
        }
        
        let item = items[index]
        if item.status != .active { return }
        
        if item.publicServices.count == 1, item.publicServices[0].isActive {
            model.publicServiceOpener.openPublicService(
                type: item.publicServices[0].type,
                contextMenu: item.publicServices[0].contextMenu,
                in: view)
        } else {
            view.open(module: PublicServiceCategoryModule(
                category: item,
                opener: model.publicServiceOpener))
        }
    }
    
    func updateServices() {
        let isFirstLoading = model.allItems.isEmpty
        
        if isFirstLoading {
            view.setState(state: .loading)
        }
        
        apiClient
            .getPublicServices()
            .observe { [weak self] (event) in
                switch event {
                case .next(let response):
                    self?.storage?.savePublicServicesResponse(response: response)
                    self?.processResponse(response: response)
                case .failed(let error):
                    if let cachedResponse = self?.storage?.getPublicServicesResponse() {
                        self?.processResponse(response: cachedResponse)
                    } else {
                        self?.showNoInternetTemplate(error)
                    }
                default:
                    return
                }
                if isFirstLoading {
                    self?.view.setState(state: .ready)
                }
            }
            .dispose(in: disposedBag)
    }

    func checkReachability() {
        onNetworkStatus(isReachable: ReachabilityHelper.shared.isReachable())
    }

    private func processResponse(response: PublicServiceResponse) {
        let validatorTask: PublicServiceCodeValidator = { [weak self] code in
            guard let self = self else { return false }
            return self.model.publicServiceOpener.canOpenPublicService(type: code)
        }
        let allItems = response
            .publicServicesCategories
            .map { PublicServiceCategoryViewModel(model: $0, typeValidator: validatorTask) }
            .filter {
                $0.publicServices.count > 1
                || ($0.publicServices.count == 1
                    && $0.publicServices[0].isActive) }
        if allItems == model.allItems {
            return
        }
        model.allItems = allItems
        
        configureTabs(from: response.tabs)
        
        model.additionalObjects = response.additionalElements
    }
    
    private func showNoInternetTemplate(_ error: NetworkError) {
        GeneralErrorsHandler.process(
            error: .init(networkError: error),
            with: { [weak self] in
                self?.updateServices()
            },
            didRetry: false,
            in: view)
    }

    func searchClick() {
        view.open(module: PublicServiceSearchModule(publicServicesCategories: model.allItems,
                                                    opener: model.publicServiceOpener))
    }
    
    func getTabsViewModel() -> TabSwitcherViewModel {
        return model.publicServiceTabsViewModel
    }
    
    func getItems(hasChip: Bool) -> [PublicServiceCategoryViewModel] {
        return model.visibleItems.filter({
            $0.chips?.contains(where: {[weak model] in
                $0.tab == model?.currentTab?.rawValue
            }) == hasChip})
    }
    
    func getNewsData() -> DSHalvedCardCarouselModel? {
        return model.additionalObjects?.filter({$0.tabCodes.contains(where: {$0 == model.currentTab})}).first?.halvedCardCarouselOrg
    }
    
    func getActiveSections() -> [PublicServiceSection] {
        var sections: [PublicServiceSection] = [.search]
        if model.publicServiceTabsViewModel.items.count > 1 {
            sections.append(.chipsTab)
        }
        if getNewsData() != nil {
            sections.append(.news)
        }
        if !getItems(hasChip: false).isEmpty {
            sections.append(.publicServices)
        }
        if !getItems(hasChip: true).isEmpty {
            sections.append(.specialServices)
        }
        return sections
    }
    
    // MARK: - Private Methods
    private func configureTabs(from responseTabs: [PublicServiceTab]) {
        let items = responseTabs.compactMap { TabSwitcherModel(id: $0.code.rawValue, title: $0.name) }
        if items.count == .zero {
            model.visibleItems = model.allItems
            return
        }
        model.publicServiceTabsViewModel = .init(items: items)
        model.publicServiceTabsViewModel.action = { [weak self] tabIndex in
            guard let self = self else { return }
            self.handleItems(by: PublicServiceTabType(
                rawValue: self.model.publicServiceTabsViewModel.items[tabIndex].id) ?? .defaultValue)
        }
        
        if let currentTab = model.currentTab, responseTabs.first(where: { $0.code == currentTab }) != nil {
            handleItems(by: currentTab)
            return
        }
        handleItems(by: .defaultValue)
    }
    
    private func handleItems(by tabType: PublicServiceTabType) {
        model.publicServiceTabsViewModel.items.forEach {
            $0.isSelected = $0.id == tabType.rawValue
        }
        model.currentTab = tabType
        model.visibleItems = model.allItems.filter { $0.tabCodes.contains(tabType) }
        view.reloadSelectedTabItems()
    }
}

private extension PublicServiceCategoriesListPresenter {
    enum Constants {
        static let newsAction = "news"
        static let allNews = "allNews"
    }
}
