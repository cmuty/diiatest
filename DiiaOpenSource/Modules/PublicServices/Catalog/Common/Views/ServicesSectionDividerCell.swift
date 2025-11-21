
import DiiaUIComponents
import UIKit

final class ServicesSectionDividerCell: BaseCollectionNibView {
    
    private var footer = UIView().withHeight(1)
    var paddingConstraints: AnchoredConstraints?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupSubviews() {
        footer.backgroundColor = Constants.footerColor
        addSubview(footer)
        paddingConstraints = footer.fillSuperview()
    }
    
    func configure(padding: UIEdgeInsets = Constants.cellPadding) {
        paddingConstraints?.leading?.constant = padding.left
        paddingConstraints?.trailing?.constant = -padding.right
        paddingConstraints?.top?.constant = padding.top
        paddingConstraints?.bottom?.constant = -padding.bottom
    }
}

private extension ServicesSectionDividerCell {
    enum Constants {
        static let cellPadding = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        static let footerColor = UIColor.white.withAlphaComponent(0.4)
    }
}
