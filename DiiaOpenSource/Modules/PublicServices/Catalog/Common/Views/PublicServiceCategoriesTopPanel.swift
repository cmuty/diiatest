import UIKit
import DiiaUIComponents

protocol PublicServiceCategoriesTopPanelDelegate: AnyObject {
    func didSelectSearch()
}

class PublicServiceCategoriesTopPanel: BaseCollectionNibCell {
    
    // MARK: - Properties
    private var searchView = BoxView(subview: UIView())
    
    weak var delegate: PublicServiceCategoriesTopPanelDelegate?
    
    // MARK: - Lifecycle
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }
    
    private func setupSubviews() {
        let searchLabel = UILabel().withParameters(font: FontBook.usualFont)
        searchLabel.text = R.Strings.public_services_search.localized()
        searchLabel.textColor = .lightGray
        let searchImage = UIImageView(image: R.image.search_light.image)
            .withSize(Constants.imageSize)
        let searchBackground = UIView()
        searchBackground.backgroundColor = .white
        searchBackground.layer.cornerRadius = Constants.cornerRadius
        searchBackground.addSubviews([searchImage, searchLabel])
        
        searchLabel.anchor(trailing: searchBackground.trailingAnchor,
                           padding: .allSides(Constants.padding))
        
        searchImage.anchor(leading: searchBackground.leadingAnchor,
                           trailing: searchLabel.leadingAnchor,
                           padding: .allSides(Constants.padding))
        
        searchLabel.centerYAnchor.constraint(
            equalTo: searchBackground.centerYAnchor).isActive = true
        
        searchImage.centerYAnchor.constraint(
            equalTo: searchBackground.centerYAnchor).isActive = true
        
        searchView = BoxView(subview: searchBackground).withConstraints(insets: Constants.searchInsets)
        addSubview(searchView)
        searchView.fillSuperview()
        searchView.withHeight(Constants.searchHeight)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(searchClick))
        searchView.addGestureRecognizer(tap)
        searchView.isUserInteractionEnabled = true
        
        setupAccessibility()
    }
    
    // MARK: - Public Methods
    func configure(delegate: PublicServiceCategoriesTopPanelDelegate? = nil) {
        self.delegate = delegate
    }
    
    // MARK: - Private Methods
    private func setupAccessibility() {
        searchView.accessibilityIdentifier = Constants.searchViewComponentId
    }
    
    // MARK: - Actions
    @objc private func searchClick() {
        delegate?.didSelectSearch()
    }
}

private extension PublicServiceCategoriesTopPanel {
    enum Constants {
        static let searchViewComponentId = "search_services"
        static let searchInsets = UIEdgeInsets(top: 8, left: 24, bottom: 0, right: 24)
        static let imageSize = CGSize(width: 24, height: 24)
        static let cornerRadius: CGFloat = 16
        static let padding: CGFloat = 8
        static let searchHeight: CGFloat = 40
    }
}
