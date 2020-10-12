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

final class Device: Encodable {
    
    enum Button: String, CaseIterable {
        case home
        case lock
        case soundDown
        case soundUp
    }
    
    enum Property: String, CaseIterable {
        case airplaneModeEnabled
        case wifiEnabled
        case cellularDataEnabled
        case bluetoothEnabled
        case orientation
        case brightness
        case volume
    }
        
    static let current = Device()
    
    let os = "ios"
    
    let driverVersion = "1.1.0"
    let channelX = 0
    let channelY = 0
    
    let systemName: String
    let systemVersion: String
    let bluetoothName: String

    let deviceWidth: Double
    let deviceHeight: Double
    let channelWidth: Double
    let channelHeight: Double
    
    let isSimulator: Bool
    
    let modelName = UIDevice.modelName.replacingOccurrences(of: "Simulator ", with: "")
        
    private(set) var applications: [Application] = []
    let screenCapturePort = Int.random(in: 32000..<64000)

    let systemProperties = Property.allCases.map { $0.rawValue }
    let systemButtons = Button.allCases.map { $0.rawValue }
    
    private init() {
        let uiDevice = UIDevice.current
        self.systemVersion = uiDevice.systemVersion
        self.bluetoothName = uiDevice.name
        self.systemName = modelName + " - " + systemVersion
        
        let screenScale = UIScreen.main.scale
        let screenNativeBounds = XCUIScreen.main.screenshot().image.size
        let screenShotWidth = screenNativeBounds.width * screenScale
        let screenShotHeight = screenNativeBounds.height * screenScale
        
        self.channelWidth = Double(screenShotWidth)
        self.channelHeight = Double(screenShotHeight)
        
        var ratio:Double = 1.0
        ratio = channelHeight / Double(screenNativeBounds.height);
        
        self.deviceWidth = Double(channelWidth / ratio)
        self.deviceHeight = Double(channelHeight / ratio)
        
        #if targetEnvironment(simulator)
        self.isSimulator = true
        #else
        self.isSimulator = false
        #endif
    }
    
    func setApplications(_ applications: [String]) {
        self.applications = applications.map { Application(label: "CFBundleName", packageName: String($0), version: "", icon: DefaultAppIcon()) }
    }
}
