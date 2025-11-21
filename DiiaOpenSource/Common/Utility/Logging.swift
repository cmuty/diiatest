import Foundation
import DiiaNetwork
import DiiaUIComponents

func log(_ items: Any...) {
    if EnvironmentVars.isInDebug {
        items.forEach { print($0) }
    }
}

struct PrintLogger: NetworkLoggerProtocol, UIComponentsLogger {
    func log(_ items: Any...) {
        if EnvironmentVars.isInDebug {
            items.forEach { print($0) }
        }
    }
}
