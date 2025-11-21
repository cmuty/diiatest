import Foundation
import DiiaMVPModule
import DiiaCommonTypes
import DiiaCommonServices

class PaymentManager: NSObject, PaymentManagerProtocol {
    func startPayment(_ paymentRequest: DiiaCommonTypes.PaymentRequestModel, in view: any DiiaMVPModule.BaseView, callback: @escaping (DiiaCommonServices.PaymentResult) -> Void) {
        TemplateHandler.handle(Constants.notImplementedAlert, in: view, callback: { action in
            callback(.template(action: action))
        })
    }
    
    private enum Constants {
        static let notImplementedAlert = AlertTemplate(
            type: .middleCenterAlignAlert,
            isClosable: false,
            data: .init(
                icon: nil,
                title: "Не опубліковано",
                description: "На жаль, поточна реалізація включає закриті партнерські бібліотеки, тому не може бути опублікованою. Можете імплементувати цей функціонал власними силами",
                mainButton: .init(title: "Ок", icon: nil, action: .cancel),
                alternativeButton: nil
            ))
    }
}
