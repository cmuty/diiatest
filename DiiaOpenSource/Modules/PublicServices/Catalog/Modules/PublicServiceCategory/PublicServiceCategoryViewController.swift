
import UIKit
import DiiaMVPModule
import DiiaUIComponents

protocol PublicServiceCategoryView: BaseView {
    func setTitle(title: String)
    func setSearchVisible(isVisible: Bool)
    func addList(list: DSListViewModel)
}

final class PublicServiceCategoryViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet private weak var navigation: TopNavigationView!
    @IBOutlet private weak var tableStackView: UIStackView!
    @IBOutlet private weak var searchView: UIView!
    @IBOutlet private weak var searchLabel: UILabel!

    // MARK: - Properties
    var presenter: PublicServiceCategoryAction!
    
    // MARK: - Init
    init() {
        super.init(nibName: PublicServiceCategoryViewController.className, bundle: Bundle.main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialSetup()
        presenter.configureView()
    }
    
    // MARK: - Configuration
    private func initialSetup() {
        setupSearchView()
        view.addBackgroundImage(R.image.light_background.image)
        navigation.setupOnClose { [weak self] in
            self?.closeModule(animated: true)
        }
        navigation.setupOnContext(callback: nil)
        
        setupAccessibility()
    }
    
    private func setupSearchView() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        searchView.addGestureRecognizer(tapRecognizer)
        searchView.isUserInteractionEnabled = true
        
        searchLabel.font = FontBook.usualFont
        searchLabel.text = R.Strings.public_services_search.localized()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(searchClick))
        searchLabel.addGestureRecognizer(tap)
        searchLabel.isUserInteractionEnabled = true
    }
    
    private func setupAccessibility() {
        navigation.accessibilityIdentifier = Constants.topGroupComponentId
        tableStackView.accessibilityIdentifier = Constants.listComponentId
        searchView.accessibilityIdentifier = Constants.searchViewComponentId
    }
    
    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func searchClick() {
        presenter.searchClick()
    }
}

// MARK: - View logic
extension PublicServiceCategoryViewController: PublicServiceCategoryView {
    
    func setTitle(title: String) {
        navigation.setupTitle(title: title)
    }
    
    func setSearchVisible(isVisible: Bool) {
        searchView.isHidden = !isVisible
    }
    
    func addList(list: DSListViewModel) {
        tableStackView.safelyRemoveArrangedSubviews()
        let view = DSWhiteColoredListView()
        view.configure(viewModel: list)
        tableStackView.addArrangedSubview(view)
    }
}

// MARK: - Constants
extension PublicServiceCategoryViewController {
    private enum Constants {
        static let topGroupComponentId = "top_group_subcategories"
        static let listComponentId = "services_list"
        static let searchViewComponentId = "search_services"
    }
}
