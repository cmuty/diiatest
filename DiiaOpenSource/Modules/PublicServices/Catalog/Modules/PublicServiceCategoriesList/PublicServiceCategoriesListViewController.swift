
import UIKit
import DiiaMVPModule
import DiiaUIComponents
import DiiaCommonTypes

protocol PublicServiceCategoriesListView: BaseView {
    func setState(state: LoadingState)
    func reloadSelectedTabItems()
}

final class PublicServiceCategoriesListViewController: UIViewController {
    
    // MARK: - Outlets
    private let topView = TopNavigationBigView()
    private let contentLoadingView = ContentLoadingView()
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let emptyLabel = UILabel()
    
    // MARK: - Properties
    var presenter: PublicServiceCategoriesListAction!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSubviews()
        setupCollectionView()
        
        title = R.Strings.services_list_title.localized()
        emptyLabel.font = FontBook.detailsTitleFont
        emptyLabel.text = R.Strings.services_unavailable.localized()
        topView.configure(viewModel: .init(title: R.Strings.services_list_title.localized()))
        presenter.configureView()
        
        setupAccessibility()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.updateServices()
    }

    // MARK: - Configuration
    
    private func setupSubviews() {
        view.backgroundColor = .clear
        collectionView.backgroundColor = .clear
        contentLoadingView.backgroundColor = .clear
        topView.backgroundColor = .clear
        
        contentLoadingView.addSubview(collectionView)
        collectionView.fillSuperview()
        let contentStack = UIStackView.create(views: [topView, contentLoadingView])
        view.addSubviews([contentStack, emptyLabel])
        
        emptyLabel.anchor(leading: view.leadingAnchor,
                          trailing: view.trailingAnchor,
                          padding: .allSides(Constants.emptyLabelPadding))
        
        contentStack.fillSuperview()
    }
    
    private func setupCollectionView() {
        collectionView.register(PublicServiceCategoriesTopPanel.self,
                                forCellWithReuseIdentifier: PublicServiceCategoriesTopPanel.reuseID)
        collectionView.register(PublicServiceShortCollectionCell.self,
                                forCellWithReuseIdentifier: PublicServiceShortCollectionCell.reuseID)
        collectionView.register(GenericCollectionViewCell.self,
                                forCellWithReuseIdentifier: GenericCollectionViewCell.reuseID)
        collectionView.register(UICollectionViewCell.self,
                                forCellWithReuseIdentifier: String(describing: UICollectionViewCell.self))
        collectionView.register(ServicesSectionDividerCell.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: ServicesSectionDividerCell.reuseID)
        collectionView.register(ServicesSectionDividerCell.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: ServicesSectionDividerCell.reuseID)
        collectionView.register(TabSwitcherCollectionCell.self,
                                forCellWithReuseIdentifier: TabSwitcherCollectionCell.reuseID)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.setCollectionViewLayout(createLayout(), animated: true)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] section, environment in
            let containerSize = environment.container.effectiveContentSize
            let activeSection = self?.presenter.getActiveSections()[section]
            return activeSection?.sectionLayout(for: containerSize) ?? nil
        }
        return layout
    }
    
    private func setupAccessibility() {
        topView.accessibilityIdentifier = Constants.topViewComponentId
        collectionView.accessibilityIdentifier = Constants.bodyComponentId
    }
}

// MARK: - View logic
extension PublicServiceCategoriesListViewController: PublicServiceCategoriesListView {
    func setState(state: LoadingState) {
        contentLoadingView.setLoadingState(state)
        topView.isHidden = state == .loading
        collectionView.isHidden = state == .loading && presenter.numberOfItems(withChips: false) == 0
        emptyLabel.isHidden = state == .loading || !collectionView.isHidden
    }

    func reloadSelectedTabItems() {
        update()
    }

    private func update() {
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        collectionView.flashScrollIndicators()
    }

    func showProgress() {
        contentLoadingView.setLoadingState(.loading)
    }

    func hideProgress() {
        contentLoadingView.setLoadingState(.ready)
    }
}

// MARK: - UICollectionViewDataSource
extension PublicServiceCategoriesListViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return presenter.getActiveSections().count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let activeSection = presenter.getActiveSections()[section]
        switch activeSection {
        case .search: return 1
        case .chipsTab: return presenter.getTabsViewModel().items.count
        case .news: return 1
        case .publicServices: return presenter.numberOfItems(withChips: false)
        case .specialServices: return presenter.numberOfItems(withChips: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let activeSection = presenter.getActiveSections()[indexPath.section]
        switch activeSection {
        case .search:
            guard let headerView = collectionView.dequeueReusableCell(
                withReuseIdentifier: PublicServiceCategoriesTopPanel.reuseID,
                for: indexPath) as? PublicServiceCategoriesTopPanel else {
                return UICollectionViewCell()
            }
            headerView.configure(delegate: self)
            return headerView
        case .chipsTab:
            let tabVM = presenter.getTabsViewModel()
            guard let chipsTabCell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TabSwitcherCollectionCell.reuseID,
                for: indexPath) as? TabSwitcherCollectionCell,
                  let itemModel = tabVM.itemAt(index: indexPath.row) else {
                return UICollectionViewCell()
            }
            chipsTabCell.configure(tabItem: itemModel)
            return chipsTabCell
        case .news:
            guard let genericCell = collectionView.dequeueReusableCell(
                withReuseIdentifier: GenericCollectionViewCell.reuseID,
                for: indexPath) as? GenericCollectionViewCell,
                  let halvedModel = presenter.getNewsData() else {
                return UICollectionViewCell()
            }
            let view = DSHalvedCardCarouselBuilder().makeView(from: halvedModel,
                                                              eventHandler: presenter.handleEvent(event:))
            genericCell.configure(with: view)
            return genericCell
        case .publicServices, .specialServices:
            guard let vm = presenter.itemAt(index: indexPath.item,
                                            withChip: activeSection != .publicServices),
                  let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PublicServiceShortCollectionCell.reuseID,
                for: indexPath) as? PublicServiceShortCollectionCell else {
                return UICollectionViewCell()
            }
            let chipAtm = activeSection == .specialServices ?
            DSSquareChipStatusModel(
                name: vm.chips?.first?.text ?? .empty,
                type: vm.chips?.first?.type ?? .blue)
            : nil
            cell.configure(
                with: vm.name,
                iconName: vm.imageName,
                isActive: vm.status == .active,
                chipAtm: chipAtm)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        if let supplementaryView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: ServicesSectionDividerCell.reuseID,
            for: indexPath) as? ServicesSectionDividerCell {
            supplementaryView.configure(padding: .zero)
            return supplementaryView
        }
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegate
extension PublicServiceCategoriesListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let activeSection = presenter.getActiveSections()[indexPath.section]
        switch activeSection {
        case .publicServices, .specialServices:
            presenter.itemSelected(index: indexPath.item, withChip: activeSection != .publicServices)
        case .chipsTab:
            presenter.getTabsViewModel().itemSelected(index: indexPath.item)
        default: break
        }
    }
}

// MARK: - PublicServiceCategoriesTopPanelDelegate
extension PublicServiceCategoriesListViewController: PublicServiceCategoriesTopPanelDelegate {
    func didSelectSearch() {
        presenter.searchClick()
    }
}

private extension PublicServiceCategoriesListViewController {
    enum Constants {
        static let topViewComponentId = "title_services"
        static let bodyComponentId = "body_services"
        static let tabCellHeight: CGFloat = 40
        static let emptyLabelPadding: CGFloat = 8
    }
}
