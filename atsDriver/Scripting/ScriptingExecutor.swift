import Foundation
import XCTest

class ScriptingExecutor: NSObject {
    
    enum ScriptingDriverError: Error {
        case unavailableFeature
        case unknowError
    }
    
    enum ScriptingSyntaxError: Error {
        case invalidMethod
        case invalidParameter
    }
    
    private let scriptPattern = "([^\\)]*)\\(([^\\)]*)\\)"
    
    private var actions: [String]
    
    class test:NSObject {
        let value:String
        let coordinate:XCUICoordinate
        
        init(value:String, coordinate:XCUICoordinate) {
            self.value = value
            self.coordinate = coordinate
        }
    }
    
    init(_ script: String) {
        actions = script.components(separatedBy: ";")
    }
    
    public func execute(coordinate: XCUICoordinate) throws {
        try actions.forEach {
        
            guard
                let regex = try? NSRegularExpression(pattern: scriptPattern, options: .caseInsensitive),
                let match = regex.firstMatch(in: $0, options: [], range: NSRange(location: 0, length: $0.utf16.count)),
                let functionRange = Range(match.range(at: 1), in: $0),
                let parameterRange = Range(match.range(at: 2), in: $0)
                else
            {
                throw ScriptingSyntaxError.invalidMethod
            }
            
            let function = String($0[functionRange]) + ":"
            let parameter = String($0[parameterRange])
            
            let selector = NSSelectorFromString(function);
            guard self.responds(to: selector) else {
                throw ScriptingSyntaxError.invalidMethod
            }
                        
            let result = self.perform(selector, with: test(value: parameter, coordinate: coordinate))
            if let error = result as? Error {
                throw error
            }
        }
    }
        
    @objc private func longPress(_ info: test) -> Error? {
        guard let duration = Double(info.value) else {
            return ScriptingSyntaxError.invalidParameter
        }
        
        info.coordinate.press(forDuration: duration)
        return nil;
    }
    
    private func tap(coordinate: XCUICoordinate, value: String) -> Error? {
        guard let count = Int(value) else {
            return ScriptingSyntaxError.invalidParameter
        }
        
        coordinate.tap()
        return nil;
    }
    
    /* private func setAirPlaneMode(value: String) throws {
        settingsApp.activate()
        
        let switchQuery = settingsApp.switches
        switchQuery.firstMatch.tap()
        
        app.activate()
    } */
    
    /* private func setWifiEnabled(value: String) throws {
        let settingsApp = self.settingsApp
        settingsApp.activate()
        
        settingsApp.cells.element(boundBy: 3).tap();
        
        if (settingsApp.switches.element.value(forKey: "isOn") as! Bool) == true {
            settingsApp.switches.firstMatch.tap();
        }
        
        app.activate()
    } */
    
    private func setBluetoothEnabled(value: String) throws {
        let settingsApp = self.settingsApp
        settingsApp.activate()
        
        settingsApp.cells.element(boundBy: 3).tap();
        if (settingsApp.switches.element.value(forKey: "isOn") as! Bool) == true {
            settingsApp.switches.firstMatch.tap();
        }
        
        app.activate()
    }
    
    private func setOrientation(value: String) throws {
        
        XCUIDevice.shared.orientation = .portrait
        XCUIDevice.shared.orientation = .landscapeLeft
    }
    
    /* private func getBluetoothName() throws -> String {
        return ""
    } */
    
    private var settingsApp: XCUIApplication {
        return XCUIApplication(bundleIdentifier: "com.apple.Preferences")
    }
}
