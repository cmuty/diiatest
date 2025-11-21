
import UIKit

public enum PublicServiceSection {
    case search, chipsTab, news, publicServices, specialServices
    
    public func sectionLayout(for contentSize: CGSize) -> NSCollectionLayoutSection {
        switch self {
        case .search: return containerSection(height: Constants.searchHeight)
        case .chipsTab: return chipTabsSection()
        case .news: return containerSection(height: Constants.newsHeight)
        case .publicServices: return serviceListSection(for: contentSize)
        case .specialServices: return specialListSection(for: contentSize)
        }
    }
    
    private func chipTabsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(Constants.estimatedChipWidth),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(Constants.estimatedChipSection),
                                               heightDimension: .absolute(Constants.chipHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])
        group.interItemSpacing = .fixed(Constants.interitemSpacing)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = Constants.interitemSpacing
        section.orthogonalScrollingBehavior = .continuous
        section.contentInsets = Constants.collectionInsets
        
        let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                heightDimension: .absolute(1))
        let footerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: footerSize,
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottom)
        footerSupplementary.contentInsets = .init(top: .zero,
                                                  leading: -Constants.collectionInsets.leading,
                                                  bottom: .zero,
                                                  trailing: -Constants.collectionInsets.trailing)
        section.boundarySupplementaryItems = [footerSupplementary]
        
        return section
    }
    
    private func serviceListSection(for contentSize: CGSize) -> NSCollectionLayoutSection {
        let itemWidth = (contentSize.width - Constants.interitemSpacing - Constants.padding * 2) / 2
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(itemWidth),
                                              heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .absolute(Constants.shortCellHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])
        group.interItemSpacing = .fixed(Constants.interitemSpacing)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = Constants.interitemSpacing
        section.contentInsets = Constants.collectionInsets
        
        return section
    }
    
    func specialListSection(for contentSize: CGSize) -> NSCollectionLayoutSection {
        let itemWidth = (contentSize.width - Constants.interitemSpacing - Constants.padding * 2) / 2
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(itemWidth),
                                              heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .absolute(Constants.longCellHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])
        group.interItemSpacing = .fixed(Constants.interitemSpacing)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = Constants.interitemSpacing
        section.contentInsets = Constants.collectionInsets
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                heightDimension: .absolute(1))
        let headerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top)
        section.boundarySupplementaryItems = [headerSupplementary]
        
        return section
    }
    
    func containerSection(height: CGFloat) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .absolute(height))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = Constants.containerInsets
        return section
    }
}

private extension PublicServiceSection {
    enum Constants {
        static let estimatedChipWidth: CGFloat = 40
        static let estimatedChipSection: CGFloat = 600
        static let shortCellHeight: CGFloat = 112
        static let longCellHeight: CGFloat = 138
        static let chipHeight: CGFloat = 38
        static let collectionInsets = NSDirectionalEdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        static let containerInsets = NSDirectionalEdgeInsets(top: 16, leading: .zero, bottom: .zero, trailing: .zero)
        static let interitemSpacing: CGFloat = 8
        static let padding: CGFloat = 24
        static let searchHeight: CGFloat = 48
        static let newsHeight: CGFloat = 232
    }
}
