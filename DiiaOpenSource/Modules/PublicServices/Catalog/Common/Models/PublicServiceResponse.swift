
import Foundation
import DiiaCommonTypes
import DiiaUIComponents

public struct PublicServiceResponse: Codable {
    let publicServicesCategories: [PublicServiceCategory]
    let tabs: [PublicServiceTab]
    let additionalElements: [ServiceAdditionalElement]?
}

public struct ServiceAdditionalElement: Codable {
    let tabCodes: [PublicServiceTabType]
    let halvedCardCarouselOrg: DSHalvedCardCarouselModel?
}

public struct PublicServiceCategory: Codable {
    let code: String
    let icon: String
    let name: String
    let status: PublicServiceStatus
    let visibleSearch: Bool
    let tabCodes: [PublicServiceTabType]
    let publicServices: [PublicServiceModel]
    let chips: [PublicServiceChip]?
}

public struct PublicServiceChip: Codable, Equatable {
    let tab: String
    let text: String
    let type: DSSquareChipStatusType
    
    public static func == (lhs: PublicServiceChip, rhs: PublicServiceChip) -> Bool {
        return lhs.tab == rhs.tab && lhs.text == rhs.text && lhs.type == rhs.type
    }
}

public struct PublicServiceModel: Codable {
    let status: PublicServiceStatus
    let name: String
    let code: String? // ex-PublicServiceType
    let badgeNumber: Int?
    let search: String?
    let contextMenu: [ContextMenuItem]?
}

public enum PublicServiceStatus: String, Codable, EnumDecodable, Equatable {
    public static let defaultValue: PublicServiceStatus = .inactive

    case inactive
    case active
}

public struct PublicServiceTab: Codable {
    let name: String
    let code: PublicServiceTabType
}

public enum PublicServiceTabType: String, Codable, EnumDecodable, Equatable {
    public static let defaultValue: PublicServiceTabType = .citizen

    case citizen
    case office
    case veteran
}
