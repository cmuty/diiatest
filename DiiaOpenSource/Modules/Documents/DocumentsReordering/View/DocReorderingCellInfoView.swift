import UIKit
import DiiaUIComponents

// MARK: - View Model
struct DocReorderingCellInfoViewModel {
    let title: String
    let subtitle: String?
    let rightIcon: UIImage?
    let rightIconAccessibilityLabel: String?
    let rightIconAccessibilityHint: String?
    
    init(
        title: String,
        subtitle: String?,
        rightIcon: UIImage?,
        rightIconAccessibilityLabel: String? = nil,
        rightIconAccessibilityHint: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.rightIcon = rightIcon
        self.rightIconAccessibilityLabel = rightIconAccessibilityLabel
        self.rightIconAccessibilityHint = rightIconAccessibilityHint
    }
}

// MARK: - View
class DocReorderingCellInfoView: BaseCodeView {
    private let titleLabel = UILabel().withParameters(font: FontBook.bigText)
    private let subtitleLabel = UILabel().withParameters(font: FontBook.usualFont, textColor: .statusGray)
    private let rightImage: UIImageView = UIImageView().withSize(Constants.imageSize)
    
    // MARK: - Life Cycle
    override func setupSubviews() {
        let labelsStack = UIStackView.create(
            views: [titleLabel, subtitleLabel],
            spacing: Constants.labelsSpacing)
        hstack(labelsStack,
               rightImage,
               spacing: Constants.defaultSpacing,
               alignment: .center,
               padding: Constants.paddings)
        
        setupUI()
    }
    
    // MARK: - Public Methods
    func configure(with viewModel: DocReorderingCellInfoViewModel) {
        titleLabel.text = viewModel.title
        titleLabel.accessibilityLabel = viewModel.title
        
        subtitleLabel.isHidden = viewModel.subtitle == nil
        if let subtitle = viewModel.subtitle {
            subtitleLabel.text = subtitle
            subtitleLabel.accessibilityLabel = subtitle
        }
        
        rightImage.isHidden = viewModel.rightIcon == nil
        if let rightIcon = viewModel.rightIcon {
            rightImage.image = rightIcon
            rightImage.accessibilityLabel = viewModel.rightIconAccessibilityLabel
            rightImage.accessibilityHint = viewModel.rightIconAccessibilityHint
        }
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        backgroundColor = .clear
        
        setupAccessibility()
    }
    
    // MARK: - Accessibility
    private func setupAccessibility() {
        titleLabel.isAccessibilityElement = true
        titleLabel.accessibilityTraits = .staticText
        
        subtitleLabel.isAccessibilityElement = true
        subtitleLabel.accessibilityTraits = .staticText
        
        rightImage.isAccessibilityElement = true
        rightImage.accessibilityTraits = .button
    }
}

// MARK: - Constants
extension DocReorderingCellInfoView {
    private enum Constants {
        static let imageSize = CGSize(width: 24, height: 24)
        static let defaultSpacing: CGFloat = 16
        static let labelsSpacing: CGFloat = 4
        static let paddings = UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)
    }
}
