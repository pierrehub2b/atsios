//
//  atsiosUITests.swift
//  atsiosUITests
//
//  Copyright © 2019 ATSIOS. All rights reserved.
//

import Foundation
import UIKit
import XCTest
import Embassy
import EnvoyAmbassador
import SwiftSocket

struct UIElement:Codable {
    var ElementTypeString: String
    var Value: String
    var PlaceHolderValue: String
    var Label: String
    var Identifier: String
    var X: Float
    var Y: Float
    var Width: Float
    var Height: Float
    var UId: String
}

struct ResultElement:Codable {
    var type: String
    var status: String
    var message: String
}

enum actionsEnum: String {
    case DRIVER = "driver"
    case APP = "app"
    case START = "start"
    case STOP = "stop"
    case SWITCH = "switch"
    case CAPTURE = "capture"
    case ELEMENT = "element"
    case TAP = "tap"
    case INPUT = "input"
    case SWIPE = "swipe"
    case BUTTON = "button"
    case INFO = "info"
    case QUIT = "quit"
    case EMPTY = "&empty"
}

enum deviceButtons: String {
    case HOME = "home"
    case SOUNDUP = "soundup"
    case SOUNDDOWN = "sounddown"
    case SILENTSWITCH = "silentswitch"
    case LOCK = "lock"
    case ENTER = "enter"
    case RETURN = "return"
    case ORIENTATION = "orientation"
}

class atsiosUITests: XCTestCase {
    
    let port = 8080
    var app: XCUIApplication!
    var udpClient: UDPClient!
    var currentAppIdentifier: String = ""
    var allElements: [UIElement] = [UIElement]()
    var resultElement: [String: Any] = [:]
    
    var continueExecution = true
    
    var applicationControls =
        [
         "any","other","application","group","window","sheet","drawer","alert","dialog","button","radioButton","radioGroup","checkbox","disclosureTriangle","popUpButton","comboBox","menuButton","toolbarButton","popOver",
         "keyboard","key","navigationBar","tabBar","tabGroup","toolBar","statusBar","table","tableRow","tableColumn","outline","outlineRow","browser","collectionView","slider","pageIndicator","progressIndicator",
         "activityIndicator","segmentedControl","picker","pickerWheel","switch","toogle","link","image","icon","searchField","scrollView","scrollBar","staticText","textField","secureTextField","datePicker","textView",
         "menu","menuItem","menuBar","menuBarItem","map","webView","incrementArrow","decrementArrow","timeline","ratingIndicator","valueIndicator","splitGroup","splitter","relevanceIndicator","colorWell","helpTag","matte",
         "dockItem","ruler","rulerMarker","grid","levelIndicator","cell","layoutArea","layoutItem","handle","stepper","tab","touchBar","statusItem"
        ]
    
    //var udpThread: Thread!

    override func setUp() {
        super.setUp()
        setupWebApp()
        setupApp()
        //self.udpClient = UDPClient(address: "www.apple.com", port: 80)
    }
    
    func setupUdpClient() {
        //udpThread = Thread(target: self, selector: #selector(runUdpServer), object: nil)
        //udpThread.start()
    }
    
    @objc private func runUdpServer() {
        // Create a socket connect to www.apple.com and port at 80
        udpClient = UDPClient(address: "www.apple.com", port: 80)
    }
    

    // setup the Embassy web server for testing
    private func setupWebApp() {
        let loop = try! SelectorEventLoop(selector: try! KqueueSelector())
        let server = DefaultHTTPServer(eventLoop: loop, port: 8080) {
            (
            environ: [String: Any],
            startResponse: ((String, [(String, String)]) -> Void),
            sendBody: ((Data) -> Void)
            ) in
            // Start HTTP response
            startResponse("200 OK", [])
            let query_String = environ["PATH_INFO"]! as! String
            let action = query_String.replacingOccurrences(of: "/", with: "")
            var parameters: [String] = [String]()
            
            let input = environ["swsgi.input"] as! SWSGIInput
            input { data in
                // handle the whole data here
                if let textData = String(bytes: data, encoding: .utf8) {
                    let tableData = textData.split(separator: "\n")
                    if tableData.count > 0 {
                        for index in 0...tableData.count-1 {
                            parameters.append(String(tableData[index]))
                        }
                    }
                }
            }
            self.resultElement = [:]
            if(action == "") {
                self.resultElement["status"] = -11
                self.resultElement["message"] = "unknow command"
            } else {
                self.resultElement["type"] = action
                switch action {
                    case actionsEnum.DRIVER.rawValue:
                        if(parameters.count > 0) {
                            if(actionsEnum.START.rawValue == parameters[0]) {
                                XCUIDevice.shared.perform(NSSelectorFromString("pressLockButton"))
                                XCUIDevice.shared.press(.home)
                                self.resultElement["status"] = 0
                                self.resultElement["screenCapturePort"] = 47633
                                self.driverInfoBase()
                            } else {
                                if(actionsEnum.STOP.rawValue == parameters[0]) {
                                    if(self.app != nil){
                                        self.app.terminate()
                                        self.resultElement["status"] = 0
                                        self.resultElement["message"] = "stop ats driver"
                                    }
                                    XCUIDevice.shared.perform(NSSelectorFromString("pressLockButton"))
                                    //close all apps
                                } else {
                                    if(actionsEnum.QUIT.rawValue == parameters[0]) {
                                        self.tearDown()
                                        self.resultElement["status"] = 0
                                        self.resultElement["message"] = "close ats driver"
                                    } else {
                                        self.resultElement["message"] = "missiing driver action type " + parameters[0]
                                        self.resultElement["status"] = -42
                                    }
                                }
                            }
                        } else {
                            self.resultElement["message"] = "missing driver action"
                            self.resultElement["status"] = -41
                        }
                        break
                    case actionsEnum.BUTTON.rawValue:
                        if(parameters.count > 0) {
                            if(deviceButtons.HOME.rawValue == parameters[0]) {
                                XCUIDevice.shared.press(.home)
                                self.resultElement["status"] = 0
                                self.resultElement["message"] = "press home button"
                            } else {
                                if(deviceButtons.ORIENTATION.rawValue == parameters[0]) {
                                    if(XCUIDevice.shared.orientation == .landscapeLeft) {
                                        XCUIDevice.shared.orientation = .portrait
                                        self.resultElement["status"] = 0
                                        self.resultElement["message"] = "orientation to portrait mode"
                                    } else {
                                        XCUIDevice.shared.orientation = .landscapeLeft
                                        self.resultElement["status"] = 0
                                        self.resultElement["message"] = "orientation to landscape mode"
                                    }
                                } else {
                                    self.resultElement["message"] = "unknow button " + parameters[0]
                                    self.resultElement["status"] = -42
                                }
                            }
                            
                        } else {
                            self.resultElement["message"] = "missing button action"
                            self.resultElement["status"] = -41
                        }
                        break
                    case actionsEnum.CAPTURE.rawValue:
                        self.allElements = []
                        if(self.app == nil) {
                            break
                        }
                        let debugDescriptionTable = self.app.debugDescription.split { $0.isNewline }
                        for line in debugDescriptionTable {
                            let trimmedString = line.trimmingCharacters(in: .whitespaces)
                            let trimmerStringLower = trimmedString.lowercased()
                            let match = self.applicationControls.filter { trimmerStringLower.starts(with: $0.lowercased()) }.count != 0
                            if(match && !line.contains("pid:")) {
                                var currentElement = trimmedString.split(separator: ",")
                                let type = currentElement[0].replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "(main)", with: "")
                                let uid = currentElement[1].replacingOccurrences(of: " ", with: "")
                                let x = currentElement[2].replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "")
                                let y = currentElement[3].replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "")
                                let width = currentElement[4].replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "")
                                let height = currentElement[5].replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "")
                                var label = ""
                                var id = ""
                                var placeHolderValue = ""
                                var value = ""
                                
                                if(currentElement.count > 6) {
                                    for index in 6...currentElement.count-1 {
                                        var currentElemIdentifiers = currentElement[index].split(separator: ":")
                                        let identifier = currentElemIdentifiers[0].replacingOccurrences(of: " ", with: "")
                                        if(identifier.lowercased() == "label") {
                                            label = currentElemIdentifiers[1].replacingOccurrences(of: "'", with: "").trimmingCharacters(in: .whitespaces)
                                        }
                                        
                                        if(identifier.lowercased() == "placeholdervalue") {
                                            placeHolderValue = currentElemIdentifiers[1].replacingOccurrences(of: "'", with: "").trimmingCharacters(in: .whitespaces)
                                        }
                                        
                                        if(identifier.lowercased() == "value") {
                                            value = currentElemIdentifiers[1].replacingOccurrences(of: "'", with: "").trimmingCharacters(in: .whitespaces)
                                        }
                                        
                                        if(identifier.lowercased() == "identifier") {
                                            id = currentElemIdentifiers[1].replacingOccurrences(of: "'", with: "").trimmingCharacters(in: .whitespaces)
                                        }
                                    }
                                }
                                
                                self.allElements.append(UIElement(
                                    ElementTypeString: type,
                                    Value: value,
                                    PlaceHolderValue: placeHolderValue,
                                    Label: label,
                                    Identifier: id,
                                    X: Float(x)!,
                                    Y: Float(y)!,
                                    Width: Float(width)!,
                                    Height: Float(height)!,
                                    UId: uid)
                                )
                            }
                        }
                        self.resultElement["message"] = self.convertIntoJSONString(arrayObject: self.allElements)
                        break
                    case actionsEnum.ELEMENT.rawValue:
                        if(parameters.count > 1) {
                            var element = self.retrieveElement(parameter: "identifier", field: parameters[0])
                            if(element == nil) {
                                element = self.retrieveElement(parameter: "label", field: parameters[0])
                            }
                            if(element == nil) {
                                element = self.retrieveElement(parameter: "placeholderValue", field: parameters[0])
                            }
                            if(element != nil && !element!.isHittable) {
                                element = nil
                                self.resultElement["status"] = -22
                                self.resultElement["message"] = "element not in the screen"
                            }
                            if(element != nil) {
                                if(actionsEnum.INPUT.rawValue == parameters[1]) {
                                    let text = parameters[2]
                                    if(element!.elementType.rawValue == 49 || element!.elementType.rawValue == 50) {
                                        element?.tap()
                                        if(text == actionsEnum.EMPTY.rawValue) {
                                            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: (element?.value as? String)?.count ?? 0)
                                            element?.typeText(deleteString)
                                            self.resultElement["status"] = 0
                                            self.resultElement["message"] = "element clear text"
                                        } else {
                                            element?.typeText(text)
                                            self.resultElement["status"] = 0
                                            self.resultElement["message"] = "element tap text: " + text
                                        }
                                    } else {
                                        element?.tap()
                                        self.resultElement["status"] = 0
                                        self.resultElement["message"] = "not a text input, just tap"
                                    }
                                } else {
                                    var offSetX = 0
                                    var offSetY = 0
                                    if(parameters.count > 3) {
                                        offSetX = Int(parameters[2])!
                                        offSetY = Int(parameters[3])!
                                    }
                                    
                                    let calculateX = Double(element?.frame.minX ?? 0) + Double(offSetX)
                                    let calculateY = Double(element?.frame.minY ?? 0) + Double(offSetY)
                                    
                                    if(actionsEnum.TAP.rawValue == parameters[1]) {
                                        self.tapCoordinate(at: calculateX, and: calculateY)
                                        self.resultElement["status"] = 0
                                        self.resultElement["message"] = "tap on element"
                                    } else {
                                        if(actionsEnum.SWIPE.rawValue == parameters[1]) {
                                            let directionX = Double(parameters[4]) ?? 0.0
                                            let directionY = Double(parameters[5]) ?? 0.0
                                            if(directionX > 0.0) {
                                                element?.swipeRight()
                                            }
                                            if(directionX < 0.0) {
                                                element?.swipeLeft()
                                            }
                                            if(directionY > 0.0) {
                                                element?.swipeUp()
                                            }
                                            if(directionY < 0.0) {
                                                element?.swipeDown()
                                            }
                                            self.resultElement["status"] = 0
                                            self.resultElement["message"] = "swipe element"
                                        }
                                    }
                                }
                            } else {
                                self.resultElement["status"] = -21
                                self.resultElement["message"] = "missing element"
                            }
                        }  else {
                            self.resultElement["message"] = "missing element action"
                            self.resultElement["status"] = -41
                        }
                        break
                    case actionsEnum.APP.rawValue:
                        if(parameters.count > 1) {
                            if(actionsEnum.START.rawValue == parameters[0]) {
                                self.app = XCUIApplication(bundleIdentifier: parameters[1])
                                self.app.launch();
                                self.resultElement["message"] = "start app " + parameters[1]
                                self.resultElement["status"] = 0
                                self.resultElement["label"] = self.app.label
                                self.resultElement["icon"] = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH4wgNCzQS2tg9zgAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAAMSURBVAjXY2DY/QYAAmYBqC0q4zEAAAAASUVORK5CYII="
                                self.resultElement["version"] = "0.0.0"
                            } else {
                                if(actionsEnum.SWITCH.rawValue == parameters[0]) {
                                    self.app = XCUIApplication(bundleIdentifier: parameters[1])
                                    self.app.launch()
                                    self.resultElement["message"] = "switch app " + parameters[1]
                                    self.resultElement["status"] = 0
                                } else {
                                    if(actionsEnum.STOP.rawValue == parameters[0]) {
                                        self.app = XCUIApplication(bundleIdentifier: parameters[1])
                                        self.app.terminate()
                                        self.resultElement["message"] = "stop app " + parameters[1]
                                        self.resultElement["status"] = 0
                                    } else {
                                        self.resultElement["message"] = "missiing app action type " + parameters[0]
                                        self.resultElement["status"] = -42
                                    }
                                }
                                
                            }
                            
                        } else {
                            self.resultElement["message"] = "missing app action"
                            self.resultElement["status"] = -41
                        }
                        break
                    case actionsEnum.INFO.rawValue:
                        if(self.app != nil) {
                            self.driverInfoBase()
                            self.resultElement["message"] = "device capabilities"
                            self.resultElement["status"] = 0
                            self.resultElement["id"] = self.app.identifier
                            self.resultElement["model"] = "simulator"
                            self.resultElement["manufacturer"] = "apple"
                            self.resultElement["brand"] = "apple"
                            self.resultElement["version"] = "1.0.0"
                            self.resultElement["bluetoothName"] = self.app.label
                        } else {
                            self.resultElement["info"] = "no app running"
                            self.resultElement["status"] = -99
                        }
                        break
                    default:
                        self.resultElement["status"] = -12
                        self.resultElement["message"] = "unknow command " + action
                        break
                    }
            }
            
            if let theJSONData = try?  JSONSerialization.data(
                withJSONObject: self.resultElement,
                options: []
                ),
                let theJSONText = String(data: theJSONData,
                                         encoding: String.Encoding.utf8) {
                sendBody(Data(theJSONText.utf8))
                sendBody(Data())
            }
        }
        
        // Start HTTP server to listen on the port
        try! server.start()
        
        // Run event loop
        loop.runForever()
    }
    
    func tapCoordinate(at xCoordinate: Double, and yCoordinate: Double) {
        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let coordinate = normalized.withOffset(CGVector(dx: xCoordinate, dy: yCoordinate))
        
        coordinate.tap()
    }
    
    func retrieveElement(parameter: String, field: String) -> XCUIElement? {
        var fieldValue = field.replacingOccurrences(of: "%27", with: "'")
        fieldValue = fieldValue.replacingOccurrences(of: "%22", with: "'")
        fieldValue = fieldValue.replacingOccurrences(of: "%20", with: " ")
        let predicate = NSPredicate(format: "\(parameter) == '\(fieldValue)'")
        if(self.app == nil) {
            return nil
        }
        let elem = self.app.descendants(matching: .any).element(matching: predicate)
        if(elem.exists) {
            return elem.firstMatch
        } else {
            return nil
        }
    }
    
    func convertIntoJSONString(arrayObject: [UIElement]) -> String {
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(arrayObject)
            let json = String(data: jsonData, encoding: String.Encoding.utf8) ?? "no values"
            return json
        } catch let error as NSError {
            print("Array convertIntoJSON - \(error.description)")
        }
        return ""
    }
    
    func stringify(json: Any, prettyPrinted: Bool = false) -> String {
        var options: JSONSerialization.WritingOptions = []
        if prettyPrinted {
            options = JSONSerialization.WritingOptions.prettyPrinted
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: options)
            if let string = String(data: data, encoding: String.Encoding.utf8) {
                return string
            }
        } catch {
            print(error)
        }
        
        return ""
    }
    
    func getQueryStringParameter(query_string: String, param: String) -> String {
        let params = query_string.components(separatedBy: "&")
        for item in params {
            var currentParam = item.components(separatedBy: "=")
            if(currentParam.count != 2) { return "" }
            if(currentParam[0] == param) {
                return currentParam[1]
            }
        }
        return ""
    }
    
    // set up XCUIApplication
    private func setupApp() {
        app = XCUIApplication()
        app.launchEnvironment["RESET_LOGIN"] = "1"
        app.launchEnvironment["ENVOY_BASEURL"] = "http://localhost:\(port)"
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func driverInfoBase() {
        self.resultElement["os"] = "ios"
        self.resultElement["driverVersion"] = "1.0.0"
        self.resultElement["systemName"] = "simulator"
        self.resultElement["deviceWidth"] = 100
        self.resultElement["deviceHeight"] = 100
        self.resultElement["channelWidth"] = 100
        self.resultElement["channelHeight"] = 100
        self.resultElement["channelX"] = 100
        self.resultElement["channelY"] = 100
    }
    
    func testExecuteCommand() {
        while continueExecution {
            
        }
    }

}
