//Licensed to the Apache Software Foundation (ASF) under one
//or more contributor license agreements.  See the NOTICE file
//distributed with this work for additional information
//    regarding copyright ownership.  The ASF licenses this file
//to you under the Apache License, Version 2.0 (the
//"License"); you may not use this file except in compliance
//with the License.  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing,
//software distributed under the License is distributed on an
//"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//KIND, either express or implied.  See the License for the
//specific language governing permissions and limitations
//under the License.

import Foundation
import UIKit
import XCTest
import Embassy
import EnvoyAmbassador
import Socket

class atsDriver: XCTestCase {
    
    let udpThread = DispatchQueue(label: "udpQueue", qos: .userInitiated)
    var domThread = DispatchQueue(label: "domQueue", qos: .userInitiated)
    var port = 8080
    var app: XCUIApplication!
    var currentAppIdentifier: String = ""
    var resultElement: [String: Any] = [:]
    var captureStruct: String = ""
    var flatStruct: [String: Frame] = [:]
    var thread: Thread! = nil
    var rootNode: UIElement? = nil
    var udpPort: Int = 47633
    var continueRunningValue = true
    var connectedSockets = [Int32: Socket]()
    var imgView: Data? = nil
    var lastCapture: TimeInterval = NSDate().timeIntervalSince1970
    var leveledTableCount = 0
    
    var cachedDescription: String = ""
    
    let osVersion = UIDevice.current.systemVersion
    let model = UIDevice.modelName.replacingOccurrences(of: "Simulator ", with: "")
    let simulator = UIDevice.modelName.range(of: "Simulator", options: .caseInsensitive) != nil
    let uid = UIDevice.current.identifierForVendor!.uuidString
    let bluetoothName = UIDevice.current.name
    var deviceWidth = 0.0
    var deviceHeight = 0.0
    let maxHeight = 860.0
    var ratioScreen = 1.0
    var ratioWidth = 1.0
    var ratioHeight = 1.0
    
    var continueExecution = true
    
    var applicationControls =
        [
            "any","other","application","group","window","sheet","drawer","alert","dialog","button","radioButton","radioGroup","checkbox","disclosureTriangle","popUpButton","comboBox","menuButton","toolbarButton","popOver",
            "keyboard","key","navigationBar","tabBar","tabGroup","toolBar","statusBar","table","tableRow","tableColumn","outline","outlineRow","browser","collectionView","slider","pageIndicator","progressIndicator",
            "activityIndicator","segmentedControl","picker","pickerWheel","switch","toogle","link","image","icon","searchField","scrollView","scrollBar","staticText","textField","secureTextField","datePicker","textView",
            "menu","menuItem","menuBar","menuBarItem","map","webView","incrementArrow","decrementArrow","timeline","ratingIndicator","valueIndicator","splitGroup","splitter","relevanceIndicator","colorWell","helpTag","matte",
            "dockItem","ruler","rulerMarker","grid","levelIndicator","cell","layoutArea","layoutItem","handle","stepper","tab","touchBar","statusItem"
    ]
    
    override func setUp() {
        super.setUp()
        
        
        udpThread.async {
            self.udpStart()
        }
        
        XCUIDevice.shared.perform(NSSelectorFromString("pressLockButton"))
        self.setupWebApp()
        self.setupApp()
    }
    
    func udpStart(){
        for i in 60000..<65000 {
            let (isFree, _) = checkTcpPortForListen(port: UInt16(i))
            if isFree == true {
                self.udpPort = i
                break;
            }
        }
        
        do {
            var data = Data()
            let socket = try Socket.create(family: .inet, type: .datagram, proto: .udp)
            
            repeat {
                let currentConnection = try socket.listen(forMessage: &data, on: self.udpPort)
                self.addNewConnection(socket: socket, currentConnection: currentConnection)
            } while true
        } catch let error {
            guard let socketError = error as? Socket.Error else {
                print("Unexpected error...")
                return
            }
            print("Error on socket instance creation: \(socketError.description)")
        }
    }
    
    func addNewConnection(socket: Socket, currentConnection: (bytesRead: Int, address: Socket.Address?)) {
        let bufferSize = 4000
        var offset = 0
        var index: UInt8 = 0
        
        do {
            let workItem = DispatchWorkItem {
                self.refreshView()
            }
            
            DispatchQueue.init(label: "getImg").async(execute: workItem)
            workItem.wait()
            
            var img = self.imgView
            if(img != nil) {
                repeat {
                    let thisChunkSize = ((img!.count - offset) > bufferSize) ? bufferSize : (img!.count - offset);
                    var chunk = img!.subdata(in: offset..<offset + thisChunkSize)
                    offset += thisChunkSize
                    let uint32Offset = UInt32(offset - thisChunkSize)
                    let uint32RemainingData = UInt32(img!.count - offset)
                    
                    var offSetTable = self.toByteArrary(value: uint32Offset)
                    var remainingDataTable = self.toByteArrary(value: uint32RemainingData)
                    
                    chunk.insert(contentsOf: offSetTable + remainingDataTable, at: 0)
                    
                    try socket.write(from: chunk, to: currentConnection.address!)
                    
                } while (offset < img!.count);
            }
        }
        catch let error {
            guard let socketError = error as? Socket.Error else {
                print("Unexpected error by connection at \(socket.remoteHostname):\(socket.remotePort)...")
                return
            }
            if self.continueExecution {
                print("Error reported by connection at \(socket.remoteHostname):\(socket.remotePort):\n \(socketError.description)")
            }
        }
        
    }
    
    func refreshView() {
        var img = self.imageResize(with: XCUIScreen.main.screenshot().image)
        self.imgView = UIImageJPEGRepresentation(img, 0)
    }
    
    func imageResize(with image: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: self.deviceWidth, height: self.deviceHeight), true, 0.85)
        image.draw(in: CGRect(x: 0, y: 0, width: self.deviceWidth, height: self.deviceHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? UIImage()
    }
    
    func toByteArrary<T>(value: T)  -> [UInt8] where T: UnsignedInteger, T: FixedWidthInteger{
        var bigEndian = value.bigEndian
        let count = MemoryLayout<T>.size
        let bytePtr = withUnsafePointer(to: &bigEndian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        
        return Array(bytePtr)
    }
    
    // setup the Embassy web server for testing
    private func setupWebApp() {
        
        let loop = try! SelectorEventLoop(selector: try! KqueueSelector())
        
        for i in 8080..<65000 {
            let (isFree, _) = checkTcpPortForListen(port: UInt16(i))
            if (isFree == true && i != self.udpPort) {
                self.port = i
                break;
            }
        }
        
        let server = DefaultHTTPServer(eventLoop: loop, interface: "0.0.0.0", port: self.port) {
            (
            environ: [String: Any],
            startResponse: ((String, [(String, String)]) -> Void),
            sendBody: ((Data) -> Void)
            ) in
            // Start HTTP response
            startResponse("200 OK", [("Content-Type", "application/json")])
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
                switch action {
                case ActionsEnum.DRIVER.rawValue:
                    if(parameters.count > 0) {
                        if(ActionsEnum.START.rawValue == parameters[0]) {
                            self.continueExecution = true
                            self.driverInfoBase()
                            self.resultElement["status"] = 0
                            self.resultElement["screenCapturePort"] = self.udpPort
                        } else {
                            if(ActionsEnum.STOP.rawValue == parameters[0]) {
                                if(self.app != nil){
                                    self.app.terminate()
                                    self.continueExecution = false
                                    XCUIDevice.shared.perform(NSSelectorFromString("pressLockButton"))
                                    self.resultElement["status"] = 0
                                    self.resultElement["message"] = "stop ats driver"
                                }
                            } else {
                                if(ActionsEnum.QUIT.rawValue == parameters[0]) {
                                    //self.tearDown()
                                    self.app.terminate()
                                    self.continueExecution = false
                                    XCUIDevice.shared.perform(NSSelectorFromString("pressLockButton"))
                                    self.resultElement["status"] = 0
                                    self.resultElement["message"] = "close ats driver"
                                } else if(ActionsEnum.INFO.rawValue == parameters[0]) {
                                    self.resultElement["status"] = 0
                                    self.resultElement["info"] = self.getAppInfo()
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
                case ActionsEnum.BUTTON.rawValue:
                    if(parameters.count > 0) {
                        if(DeviceButtons.HOME.rawValue == parameters[0]) {
                            XCUIDevice.shared.press(.home)
                            self.resultElement["status"] = 0
                            self.resultElement["message"] = "press home button"
                        } else {
                            if(DeviceButtons.ORIENTATION.rawValue == parameters[0]) {
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
                    
                case "capture2":
                    if(self.app == nil) {
                        self.resultElement["message"] = "no app has been launched"
                        self.resultElement["status"] = -99
                        break
                    }
                    
                    self.resultElement["message"] = "root_description"
                    self.resultElement["status"] = 0
                    self.resultElement["root"] = self.app.debugDescription
                    
                case ActionsEnum.CAPTURE.rawValue:
                    if(self.app == nil) {
                        self.resultElement["message"] = "no app has been launched"
                        self.resultElement["status"] = -99
                        break
                    }
                    
                    var description = self.app.debugDescription
                    
                    //if(self.cachedDescription != description){
                        self.cachedDescription = description;
                        
                        description = description.replacingOccurrences(of: "'\n", with: "'⌘")
                            .replacingOccurrences(of: "}}\n", with: "}}⌘")
                            .replacingOccurrences(of: "Disabled\n", with: "Disabled⌘")
                            .replacingOccurrences(of: "\n    ", with: "⌘    ")
                            .replacingOccurrences(of: "\n", with: " ")
                        var descriptionTable = description.split(separator: "⌘")
                        var leveledTable: [(Int,String)] = [(Int,String)]()
                        
                        for index in 0...descriptionTable.count-3 {
                            //no traitment of line that are not reference composants
                            var currentLine = String(descriptionTable[index])
                            var blankSpacesAtStart = 0
                            for char in currentLine.characters.indices {
                                if(currentLine[char] == " ") {
                                    blankSpacesAtStart += 1
                                } else {
                                    break
                                }
                            }
                            let level = (blankSpacesAtStart / 2) - 1
                            if(level > 0) {
                                leveledTable.append((level, currentLine))
                            }
                        }
                        
                        //                        if(self.leveledTableCount == 0) {
                        //                            self.leveledTableCount = leveledTable.count
                        //                        } else {
                        //                            if(self.leveledTableCount != leveledTable.count) {
                        //                                self.domThread = DispatchQueue(label: "domQueue", qos: .userInitiated)
                        //                            }
                        //                        }
                        
                        var intervalSinceLastCapture = NSDate().timeIntervalSince1970 - self.lastCapture
                        if(leveledTable.count == self.flatStruct.count && intervalSinceLastCapture < 2) {
                            break
                        }
                        
                        //get first line for ratio
                        var rootLine = leveledTable[0].1.split(separator: ",")
                        let levelUID = UUID().uuidString
                        
                        var x = Double(self.cleanString(input: String(rootLine[2]))) as! Double
                        var y = Double(self.cleanString(input: String(rootLine[3]))) as! Double
                        var width = Double(self.cleanString(input: String(rootLine[4]))) as! Double
                        var height = Double(self.cleanString(input: String(rootLine[5]))) as! Double
                        
                        if(height != self.deviceHeight && self.simulator) {
                            self.ratioHeight = self.deviceHeight / height
                        }

                        if(width != self.deviceWidth && self.simulator) {
                            self.ratioWidth = self.deviceWidth / width
                        }
                    
                        if(self.rootNode != nil) {
                            self.captureStruct = self.convertIntoJSONString(arrayObject: self.rootNode!)
                        } else {
                            self.captureStruct = "{}"
                        }
                        let workItem = DispatchWorkItem {
                            let rootNode = UIElement(
                                id: levelUID,
                                tag: "root",
                                clickable: false,
                                x: x * self.ratioWidth,
                                y: y * self.ratioHeight,
                                width: width * self.ratioWidth,
                                height: height * self.ratioHeight,
                                children: self.getChildrens(currentLevel: 1, currentIndex: 0, endedIndex: leveledTable.count-1, leveledTable: leveledTable),
                                attributes: [:],
                                channelY: 0,
                                channelHeight: Double(self.cleanString(input: String(rootLine[5])))
                            )
                            
                            self.flatStruct = self.getFlatStruct(rootNode: rootNode)
                            self.captureStruct = self.convertIntoJSONString(arrayObject: rootNode)
                            self.rootNode = rootNode
                            self.lastCapture = NSDate().timeIntervalSince1970
                        }
                        self.domThread.async(execute: workItem)
                        workItem.wait()
                        
                    //}
                    
                    break
                case ActionsEnum.ELEMENT.rawValue:
                    if(parameters.count > 1) {
                        let flatElement = self.flatStruct[parameters[0]]
                        if(flatElement == nil) {
                            self.resultElement["status"] = -21
                            self.resultElement["message"] = "missing element"
                            break
                        }
                        
                        if(ActionsEnum.INPUT.rawValue == parameters[1]) {
                            let text = parameters[2]
                            if(text == ActionsEnum.EMPTY.rawValue) {
                                self.tapCoordinate(at: flatElement!.x + (flatElement!.width * 0.90), and: flatElement!.y + (flatElement!.height / 2))
                                //self.clearText(x: flatElement!.x, y: flatElement!.y)
                            } else {
                                self.tapCoordinate(at: flatElement!.x, and: flatElement!.y)
                                self.app.typeText(text)
                                self.resultElement["status"] = 0
                                self.resultElement["message"] = "element tap text: " + text
                            }
                        } else {
                            var offSetX = 0
                            var offSetY = 0
                            if(parameters.count > 3) {
                                offSetX = Int(parameters[2])!
                                offSetY = Int(parameters[3])!
                            }
                            
                            let calculateX = Double(flatElement!.x ) + Double(offSetX)
                            let calculateY = Double(flatElement!.y ) + Double(offSetY)
                            
                            if(ActionsEnum.TAP.rawValue == parameters[1]) {
                                self.tapCoordinate(at: calculateX, and: calculateY)
                                self.resultElement["status"] = 0
                                self.resultElement["message"] = "tap on element"
                            } else {
                                if(ActionsEnum.SWIPE.rawValue == parameters[1]) {
                                    let directionX = Double(parameters[4]) ?? 0.0
                                    let directionY = Double(parameters[5]) ?? 0.0
                                    if(directionX > 0.0) {
                                        self.app.swipeRight()
                                    }
                                    if(directionX < 0.0) {
                                        self.app.swipeLeft()
                                    }
                                    if(directionY > 0.0) {
                                        self.app.swipeUp()
                                    }
                                    if(directionY < 0.0) {
                                        self.app.swipeDown()
                                    }
                                    self.resultElement["status"] = 0
                                    self.resultElement["message"] = "swipe element"
                                }
                            }
                        }
                    } else {
                        self.resultElement["message"] = "missing paramters action"
                        self.resultElement["status"] = -41
                    }
                    break
                case ActionsEnum.APP.rawValue:
                    if(parameters.count > 1) {
                        if(ActionsEnum.START.rawValue == parameters[0]) {
                            self.app = XCUIApplication.init(bundleIdentifier: parameters[1])
                            
                            if(self.app.state.rawValue > 0) {
                                self.app.launch()
                                self.resultElement["message"] = "start app " + parameters[1]
                                self.resultElement["status"] = 0
                                self.resultElement["label"] = self.app.label
                                self.resultElement["icon"] = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH4wgNCzQS2tg9zgAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAAMSURBVAjXY2DY/QYAAmYBqC0q4zEAAAAASUVORK5CYII="
                                self.resultElement["version"] = "0.0.0"
                            } else {
                                self.resultElement["message"] = "App is not installed on device"
                                self.resultElement["status"] = -99
                                self.app = nil
                            }
                        } else {
                            if(ActionsEnum.SWITCH.rawValue == parameters[0]) {
                                self.app = XCUIApplication(bundleIdentifier: parameters[1])
                                self.app.activate()
                                self.resultElement["message"] = "switch app " + parameters[1]
                                self.resultElement["status"] = 0
                            } else {
                                if(ActionsEnum.STOP.rawValue == parameters[0]) {
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
                case ActionsEnum.INFO.rawValue:
                    self.driverInfoBase()
                    self.resultElement["message"] = "device capabilities"
                    self.resultElement["status"] = 0
                    self.resultElement["id"] = self.uid
                    self.resultElement["model"] = self.model
                    self.resultElement["manufacturer"] = "Apple"
                    self.resultElement["brand"] = "Apple"
                    self.resultElement["version"] = self.osVersion
                    self.resultElement["bluetoothName"] = self.bluetoothName
                    self.resultElement["simulator"] = self.simulator
                    break
                default:
                    self.resultElement["status"] = -12
                    self.resultElement["message"] = "unknow command " + action
                    break
                }
            }
            
            if(action == ActionsEnum.CAPTURE.rawValue) {
                sendBody(Data(self.captureStruct.utf8))
            } else {
                if let theJSONData = try?  JSONSerialization.data(
                    withJSONObject: self.resultElement,
                    options: []
                    ),
                    let theJSONText = String(data: theJSONData,
                                             encoding: String.Encoding.utf8) {
                    sendBody(Data(theJSONText.utf8))
                }
            }
            sendBody(Data())
        }
        
        // Start HTTP server to listen on the port
        try! server.start()
        
        let endPoint = getWiFiAddress()! + ":" + String(self.port)
        fputs("ATSDRIVER_DRIVER_HOST=" + endPoint + "\n", stderr)
        
        // Run event loop
        loop.runForever()
    }
    
    func matchingStrings(input: String, regex: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return [] }
        let nsString = input as NSString
        let results  = regex.matches(in: input, options: [], range: NSMakeRange(0, nsString.length))
        return results.map { result in
            (0..<result.numberOfRanges).map {
                result.range(at: $0).location != NSNotFound
                    ? nsString.substring(with: result.range(at: $0))
                    : ""
            }
        }
    }

    
    func split(input: String, regex: String) -> [String] {
        
        guard let re = try? NSRegularExpression(pattern: regex, options: [])
            else { return [] }
        
        let nsString = input as NSString // needed for range compatibility
        let stop = "<SomeStringThatYouDoNotExpectToOccurInSelf>"
        let modifiedString = re.stringByReplacingMatches(
            in: input,
            options: [],
            range: NSRange(location: 0, length: nsString.length),
            withTemplate: "")
        return modifiedString.components(separatedBy: stop)
    }
    
    func getFlatStruct(rootNode: UIElement) -> [String: Frame] {
        var frame = Frame(x: rootNode.x, y: rootNode.y, width: rootNode.width, height: rootNode.height)
        var currentFlatStruct: [String:Frame] = [:]
        currentFlatStruct[rootNode.id] = frame
        for child in rootNode.children! {
            var c = self.getFlatStruct(rootNode: child)
            currentFlatStruct = currentFlatStruct.merging(c)
            { (current, _) in current }
        }
        return currentFlatStruct
    }
    
    func getChildrens(currentLevel: Int, currentIndex: Int, endedIndex: Int, leveledTable: [(Int,String)]) -> [UIElement] {
        var tableToReturn: [UIElement] = [UIElement]()
        if(currentIndex < leveledTable.count-1) {
            for line in currentIndex...leveledTable.count-1 {
                let levelUID = UUID().uuidString
                let currentLine = leveledTable[line]
                var splittedLine: [String] = [String]()
                
                var currentString = ""
                var stopSplitting = false
                var index = 0
                var isValue = false
                for char in currentLine.1 {
                    if(isValue) {
                        currentString += String(char)
                        if((index + 1) == currentLine.1.count) {
                            splittedLine.append(currentString)
                        }
                    } else if(currentString.contains("value")) {
                        isValue = !isValue
                        currentString += String(char)
                    } else if(char == "," && !stopSplitting){
                        splittedLine.append(currentString)
                        currentString = ""
                    } else {
                        if(char == "'") {
                            stopSplitting = !stopSplitting
                        }
                        currentString += String(char)
                        if((index + 1) == currentLine.1.count) {
                            splittedLine.append(currentString)
                        }
                    }
                    index += 1
                }
                
                if(currentLine.0 == currentLevel && endedIndex >= line) {
                    var endIn = line + 1
                    if(endIn < leveledTable.count-1) {
                        for el in endIn...leveledTable.count-1 {
                            if(leveledTable[el].0 >= currentLevel+1) {
                                endIn += 1
                            } else {
                                break
                            }
                        }
                    }
                    
                    
                    var attr: [String: String] = [String: String]()
                    
                    var label = ""
                    var placeHolder = ""
                    var identifier = ""
                    var value = ""
                    let pattern = "'(.*?)'"
                    for str in splittedLine {
                        if(str.contains("identifier")) {
                            var currentIdentifier = (self.matchingStrings(input: String(str), regex: pattern).first?[1])!
                            identifier = currentIdentifier.components(separatedBy: CharacterSet.symbols).joined()
                        }
                        if(str.contains("label")) {
                            var currentLabel = str.replacingOccurrences(of: "label:", with: "").replacingOccurrences(of: "'", with: "").trimmingCharacters(in: NSCharacterSet.whitespaces)
                            label = currentLabel.components(separatedBy: CharacterSet.symbols).joined()
                        }
                        if(str.contains("placeholderValue")) {
                            var currentPlaceHolder = (self.matchingStrings(input: String(str), regex: pattern).first?[1])!
                            placeHolder = currentPlaceHolder.components(separatedBy: CharacterSet.symbols).joined()
                        }
                        if(str.contains("value")) {
                            var valueTable = str.split(separator: ":")
                            if(valueTable.count == 2) {
                                let val = valueTable[1]
                                var currentValue = val.trimmingCharacters(in: .whitespacesAndNewlines)
                                value = currentValue.components(separatedBy: CharacterSet.symbols).joined()
                            }
                        }
                    }
                    
                    var enabled = true
                    if(currentLine.1.contains("Disabled")) {
                        enabled = false
                    }
                    
                    var selected = false
                    if(currentLine.1.contains("Selected")) {
                        selected = true
                    }
                    
                    
                    attr["text"] = label
                    attr["description"] = placeHolder
                    attr["checkable"] = String(self.cleanString(input: String(splittedLine[0])) == "checkbox")
                    attr["enabled"] = String(enabled)
                    attr["identifier"] = identifier
                    attr["selected"] = String(selected)
                    attr["editable"] = String(enabled)
                    attr["numeric"] = "false"
                    attr["value"] = value
                    
                    let x = Double(self.cleanString(input: String(splittedLine[2]))) as! Double
                    let y = Double(self.cleanString(input: String(splittedLine[3]))) as! Double
                    let width = Double(self.cleanString(input: String(splittedLine[4]))) as! Double
                    let height = Double(self.cleanString(input: String(splittedLine[5]))) as! Double
                    
                    tableToReturn.append(UIElement(
                        id: levelUID,
                        tag: self.cleanString(input: String(splittedLine[0])),
                        clickable: true,
                        x: x * self.ratioWidth,
                        y: y * self.ratioHeight,
                        width: width * self.ratioWidth,
                        height: height * self.ratioHeight,
                        children: self.getChildrens(currentLevel: currentLevel+1, currentIndex: line+1, endedIndex: endIn, leveledTable: leveledTable),
                        attributes: attr,
                        channelY: nil,
                        channelHeight: nil
                    ))
                }
            }
        }
        
        return tableToReturn
    }
    
    func getAppInfo() -> String {
        if(self.app != nil) {
            let pattern = "'(.*?)'"
            var packageName = self.matchingStrings(input: String(self.app.description), regex: pattern).first?[1]
            var informations: [String:String] = [:]
            informations["packageName"] = packageName
            informations["activity"] = getStateStringValue(rawValue: self.app.state.rawValue)
            informations["system"] = model + " " + osVersion
            informations["label"] = self.app.label
            informations["icon"] = ""
            informations["version"] = ""
            informations["os"] = "ios"
            return self.convertIntoJSONString(arrayObject: informations)
        } else {
            return ""
        }
    }
    
    func cleanString(input: String) -> String {
        var output = input.replacingOccurrences(of: "{", with: "")
        output = output.replacingOccurrences(of: "}", with: "")
        return output.replacingOccurrences(of: " ", with: "")
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
    
    func convertIntoJSONString(arrayObject: UIElement) -> String {
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
    
    func convertIntoJSONString(arrayObject: [String:String]) -> String {
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
        app.launchEnvironment["ENVOY_BASEURL"] = "http://localhost:\(self.port)"
    }
    
    func driverInfoBase() {
        let screenNativeBounds = XCUIScreen.main.screenshot().image
        self.deviceWidth = Double(screenNativeBounds.size.width)
        self.deviceHeight = Double(screenNativeBounds.size.height)
        if(self.deviceHeight > self.maxHeight && self.simulator) {
            self.ratioScreen = self.maxHeight / self.deviceHeight
            self.deviceWidth = self.deviceWidth * self.ratioScreen
            self.deviceHeight = self.deviceHeight * self.ratioScreen
        }
        
        self.resultElement["os"] = "ios"
        self.resultElement["driverVersion"] = "1.0.0"
        self.resultElement["systemName"] = model + " - " + osVersion
        self.resultElement["deviceWidth"] = Double(screenNativeBounds.size.width)
        self.resultElement["deviceHeight"] = Double(screenNativeBounds.size.height)
        self.resultElement["channelWidth"] = Double(screenNativeBounds.size.width)
        self.resultElement["channelHeight"] = Double(screenNativeBounds.size.height)
        self.resultElement["channelX"] = Double(screenNativeBounds.size.width)
        self.resultElement["channelY"] = Double(screenNativeBounds.size.height)
    }
    
    
    
    func checkTcpPortForListen(port: in_port_t) -> (Bool, descr: String) {
        
        let socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0)
        if socketFileDescriptor == -1 {
            return (false, "SocketCreationFailed, \(descriptionOfLastError())")
        }
        
        var addr = sockaddr_in()
        let sizeOfSockkAddr = MemoryLayout<sockaddr_in>.size
        addr.sin_len = __uint8_t(sizeOfSockkAddr)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = Int(OSHostByteOrder()) == OSLittleEndian ? _OSSwapInt16(port) : port
        addr.sin_addr = in_addr(s_addr: inet_addr("0.0.0.0"))
        addr.sin_zero = (0, 0, 0, 0, 0, 0, 0, 0)
        var bind_addr = sockaddr()
        memcpy(&bind_addr, &addr, Int(sizeOfSockkAddr))
        
        if Darwin.bind(socketFileDescriptor, &bind_addr, socklen_t(sizeOfSockkAddr)) == -1 {
            let details = descriptionOfLastError()
            release(socket: socketFileDescriptor)
            return (false, "\(port), BindFailed, \(details)")
        }
        if listen(socketFileDescriptor, SOMAXCONN ) == -1 {
            let details = descriptionOfLastError()
            release(socket: socketFileDescriptor)
            return (false, "\(port), ListenFailed, \(details)")
        }
        release(socket: socketFileDescriptor)
        return (true, "\(port) is free for use")
    }
    
    func release(socket: Int32) {
        Darwin.shutdown(socket, SHUT_RDWR)
        close(socket)
    }
    
    func descriptionOfLastError() -> String {
        return String.init(cString: (UnsafePointer(strerror(errno))))
    }
    
    func getWiFiAddress() -> String? {
        var address : String?
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 only
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if  name == "en0" {
                    
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                } else if name == "en1" {
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(1), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        
        return address
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testExecuteCommand() {
        while continueExecution {
            
        }
    }
}
