
import UIKit
import DiiaUIComponents

/// design_system_code: serviceCardMlс
class PublicServiceShortCollectionCell: BaseCollectionNibCell {

    private let nameLabel = UILabel().withParameters(font: FontBook.usualFont)
    private let chipView = DSSquareChipStatusView()
    private let iconView = UIImageView()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }
    
    private func setupSubviews() {
        backgroundColor = .white.withAlphaComponent(Constants.halfAlpha)
        layer.cornerRadius = Constants.cornerRadius
        
        iconView.layer.cornerRadius = Constants.cornerRadius
        
        let stackView = UIStackView.create(
            views: [nameLabel, chipView],
            spacing: Constants.stackSpacing,
            alignment: .leading)
        
        addSubviews([iconView, stackView])
        iconView.anchor(top: topAnchor,
                        leading: leadingAnchor,
                        padding: .allSides(Constants.padding),
                        size: Constants.imageSize)
        stackView.anchor(leading: leadingAnchor,
                         bottom: bottomAnchor,
                         trailing: trailingAnchor,
                         padding: .allSides(Constants.padding))
    }
    
    func configure(with title: String, iconName: String, isActive: Bool, chipAtm: DSSquareChipStatusModel? = nil) {
        accessibilityLabel = title
        
        nameLabel.text = title
        nameLabel.alpha = isActive ? Constants.withoutAlpha : Constants.halfAlpha
        
        chipView.isHidden = chipAtm == nil
        if let chipAtm {
            chipView.configure(with: chipAtm)
        }
        
        iconView.image = DSImageNameResolver.instance.imageForCode(imageCode: iconName)
        iconView.alpha = isActive ? Constants.withoutAlpha : Constants.halfAlpha
    }
}

extension PublicServiceShortCollectionCell {
    private enum Constants {
        static let halfAlpha: CGFloat = 0.5
        static let withoutAlpha: CGFloat = 1
        static let imageSize = CGSize(width: 32, height: 32)
        static let cornerRadius: CGFloat = 16
        static let padding: CGFloat = 16
        static let stackSpacing: CGFloat = 8
    }
}
