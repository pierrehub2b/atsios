//
//  atsiosUITests.swift
//  atsiosUITests
//
//  Created by Laura Chiudini on 31/07/2019.
//  Copyright © 2019 CAIPTURE. All rights reserved.
//

import Foundation
import UIKit
import XCTest
import Embassy
import EnvoyAmbassador

enum Actions {
    case launch
    case getDom
    case getElement
    case text
    case tap
    case null
}

class ActionElement {
    var Action: Actions = Actions.null
    var Command: String = ""
}

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

class atsiosUITests: XCTestCase {
    
    let port = 8080
    var app: XCUIApplication!

    var stack: Array<ActionElement> = Array()
    var currentAppIdentifier: String = ""
    
    var allElements: [UIElement] = [UIElement]()
    
    var continueExecution = true
    
    var applicationControls =
        [
         "any","other","application","group","window","sheet","drawer","alert","dialog","button","radiobutton","radiogroup","checkbox","disclosuretriangle","popupbutton","combobox","menubutton","toolbarbutton","popover",
         "keyboard","key","navigationbar","tabbar","tabgroup","toolbar","statusbar","table","tablerow","tablecolumn","outline","outlinerow","browser","collectionview","slider","pageindicator","progressindicator",
         "activityindicator","segmentedcontrol","picker","pickerwheel","switch","toogle","link","image","icon","searchfield","scrollview","scrollbar","statictext","textfield","securetextfield","datepicker","textview",
         "menu","menuitem","menubar","menubaritem","map","webview","incrementarrow","decrementarrow","timeline","ratingindicator","valueindicator","splitgroup","splitter","relevanceindicator","colorwell","helptag","matte",
         "dockitem","ruler","rulermarker","grid","levelindicator","cell","layoutarea","layoutitem","handle","stepper","tab","touchbar","statusitem"
        ]

    override func setUp() {
        super.setUp()
        setupWebApp()
        setupApp()
    }
    
    func getEnumStringValue(rawValue: UInt) -> String {
        switch rawValue {
        case 0:
            return "any"
        case 1:
            return "other"
        case 2:
            return "application"
        case 3:
            return "group"
        case 4:
            return "window"
        case 5:
            return "sheet"
        case 6:
            return "drawer"
        case 7:
            return "alert"
        case 8:
            return "dialog"
        case 9:
            return "button"
        case 10:
            return "radioButton"
        case 11:
            return "radioGrouo"
        case 12:
            return "checkBox"
        case 13:
            return "disclosureTriangle"
        case 14:
            return "popUpButton"
        case 15:
            return "comboBox"
        case 16:
            return "menuButton"
        case 17:
            return "toolbarButton"
        case 18:
            return "popOver"
        case 19:
            return "keyboard"
        case 20:
            return "key"
        case 21:
            return "navigationBar"
        case 22:
            return "tabBar"
        case 23:
            return "tabGroup"
        case 24:
            return "toolBar"
        case 25:
            return "statusBar"
        case 26:
            return "table"
        case 27:
            return "tableRow"
        case 28:
            return "tableColumn"
        case 29:
            return "outline"
        case 30:
            return "outlineRow"
        case 31:
            return "browser"
        case 32:
            return "collectionView"
        case 33:
            return "slider"
        case 34:
            return "pageIndicator"
        case 35:
            return "progressIndicator"
        case 36:
            return "activityIndicator"
        case 37:
            return "segmentedControl"
        case 38:
            return "picker"
        case 39:
            return "pickerWheel"
        case 40:
            return "switch"
        case 41:
            return "toggle"
        case 42:
            return "link"
        case 43:
            return "image"
        case 44:
            return "icon"
        case 45:
            return "searchField"
        case 46:
            return "scrollView"
        case 47:
            return "scrollBar"
        case 48:
            return "staticText"
        case 49:
            return "textField"
        case 50:
            return "secureTextField"
        case 51:
            return "datePicker"
        case 52:
            return "textView"
        case 53:
            return "menu"
        case 54:
            return "menuItem"
        case 55:
            return "menuBar"
        case 56:
            return "menuBarItem"
        case 57:
            return "map"
        case 58:
            return "webView"
        case 59:
            return "incrementArrow"
        case 60:
            return "decrementArrow"
        case 61:
            return "timeline"
        case 62:
            return "ratingIndicator"
        case 63:
            return "valueIndicator"
        case 64:
            return "splitGroup"
        case 65:
            return "splitter"
        case 66:
            return "relevanceIndicator"
        case 67:
            return "colorWell"
        case 68:
            return "helpTag"
        case 69:
            return "matte"
        case 70:
            return "dockItem"
        case 71:
            return "ruler"
        case 72:
            return "rulerMarker"
        case 73:
            return "grid"
        case 74:
            return "levelIndicator"
        case 75:
            return "cell"
        case 76:
            return "layoutArea"
        case 77:
            return "layoutItem"
        case 78:
            return "handle"
        case 79:
            return "stepper"
        case 80:
            return "tab"
        case 81:
            return "touchBar"
        case 82:
            return "statusItem"
        default:
            return "any"
        }
    }
    ///endregion

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
            let query_String = environ["QUERY_STRING"]! as! String
            
            var result = ""
            let action = self.getQueryStringParameter(query_string: query_String, param: "action")
            let parameter = self.getQueryStringParameter(query_string: query_String, param: "parameter")
            let field = self.getQueryStringParameter(query_string: query_String, param: "field")
            let textValue = self.getQueryStringParameter(query_string: query_String, param: "text")
            let xCoordinate = self.getQueryStringParameter(query_string: query_String, param: "x")
            let yCoordinate = self.getQueryStringParameter(query_string: query_String, param: "y")
            
            if(action == "") {
                result = "invalid action"
            } else {
                switch action {
                case "launch":
                    if(parameter == "") {
                        result = "invalid command"
                        break
                    }
                    self.app = XCUIApplication(bundleIdentifier: parameter)
                    self.app.launch();
                    result = "Execute action: " + action + " with command = " + parameter
                    break
                case "getDom":
                    //result = self.app.debugDescription
                    //self.allElements = [UIElement]()
                    //self.getDom()
                    //result = self.convertIntoJSONString(arrayObject: self.allElements)
                    result = ""
                    self.allElements = []
                    let debugDescriptionTable = self.app.debugDescription.split { $0.isNewline }
                    for line in debugDescriptionTable {
                        let trimmedString = line.trimmingCharacters(in: .whitespaces).lowercased()
                        let match = self.applicationControls.filter { trimmedString.starts(with: $0) }.count != 0
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
                                X: Float(x) as! Float,
                                Y: Float(y) as! Float,
                                Width: Float(width) as! Float,
                                Height: Float(height) as! Float,
                                UId: uid)
                            )
                        }
                    }
                    result = self.convertIntoJSONString(arrayObject: self.allElements)
                    break
                case "getElement":
                    if(parameter == "" && field == "") {
                        result = "invalid command"
                        break
                    }
                    let elem = self.retrieveElement(parameter: parameter, field: field)
                    if(elem != nil) {
                        result = elem.debugDescription
                    } else {
                        result = "Element not found"
                    }
                    break
                case "tap":
                    if(parameter == "" && field == "") {
                        if(xCoordinate == "" && yCoordinate == "") {
                            result = "invalid command"
                        }
                        self.tapCoordinate(at: Double(xCoordinate)!, and: Double(yCoordinate)!)
                        break
                    }
                    let elem = self.retrieveElement(parameter: parameter, field: field)
                    if(elem != nil) {
                        elem?.tap()
                    } else {
                        result = "Element not found"
                    }
                    break
                case "text":
                    if(parameter == "" && field == "" && textValue == "") {
                        result = "invalid command"
                        break
                    }
                    let elem = self.retrieveElement(parameter: parameter, field: field)
                    if(elem != nil) {
                        elem?.tap()
                        elem?.typeText(textValue)
                    } else {
                        result = "Element not found"
                    }
                    break
                case "screenshot":
                    let imageView = UIImageView(image: self.app.screenshot().image)
                    break
                default:
                    //stop the server
                    self.continueExecution = false
                    break
                }
            }
            
            sendBody(Data("\(result)".utf8))
            
            // send EOF
            sendBody(Data())
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
        let predicate = NSPredicate(format: "\(parameter) == \(fieldValue)")
        let elements = self.app.descendants(matching: .any).matching(predicate)
        if(elements.count > 0) {
            return elements.element(boundBy: 0)
        }
        return nil
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
    
    func testExecuteCommand() {
        while continueExecution {
            
        }
    }

}
