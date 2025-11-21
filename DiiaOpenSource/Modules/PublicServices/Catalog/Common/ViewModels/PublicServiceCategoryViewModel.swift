
import Foundation
import DiiaCommonTypes

struct PublicServiceCategoryViewModel: Equatable {
    let name: String
    let visibleSearch: Bool
    let status: PublicServiceStatus
    let tabCodes: [PublicServiceTabType]
    let publicServices: [PublicServiceShortViewModel]
    let chips: [PublicServiceChip]?
    
    // Set a local image from assets if emoji is not supported or don't exist.
    var imageName: String
    
    init(model: PublicServiceCategory, typeValidator: PublicServiceCodeValidator) {
        self.name = model.name
        self.visibleSearch = model.visibleSearch
        self.status = model.status
        self.tabCodes = model.tabCodes
        self.chips = model.chips
        self.publicServices = model
            .publicServices
            .map { PublicServiceShortViewModel(model: $0, validator: typeValidator) }
        
        self.imageName = model.code
    }
    
    static func == (lhs: PublicServiceCategoryViewModel, rhs: PublicServiceCategoryViewModel) -> Bool {
        return lhs.name == rhs.name
        && lhs.visibleSearch == rhs.visibleSearch
        && lhs.status == rhs.status
        && lhs.tabCodes == rhs.tabCodes
        && lhs.publicServices == rhs.publicServices
        && lhs.chips == rhs.chips
    }
}
