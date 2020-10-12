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
import XCTest
import UIKit
import Swifter

extension InfoController: Routeable {
    
    var name: String { return "info" }
    
    func handleRoutes(_ request: HttpRequest) -> HttpResponse {
        return fetchInfo()
    }
}

final class InfoController {
    
    struct InfoOutput: Encodable {
        let os = "ios"
        let driverVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let buildNumber = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        let systemName = modelName + " - " + UIDevice.current.systemVersion
        let systemCountry = NSLocale.current.regionCode
        let deviceWidth: Double
        let deviceHeight: Double
        let channelWidth: Double
        let channelHeight: Double
        let channelX = 0
        let channelY = 0
        
        let message = "device capabilities"
        let status = "0"
        let id = UIDevice.current.identifierForVendor!.uuidString
        let model = modelName
        let manufacturer = "Apple"
        let brand = "Apple"
        let version = UIDevice.current.systemVersion
        let bluetoothName = UIDevice.current.name
        let simulator = Device.current.isSimulator
        let applications: [Application]
    }
    
    static let modelName = UIDevice.modelName.replacingOccurrences(of: "Simulator ", with: "")
    
    func fetchInfo() -> HttpResponse {
        let device = Device.current
        return InfoOutput(
            deviceWidth: device.deviceWidth,
            deviceHeight: device.deviceHeight,
            channelWidth: device.channelWidth,
            channelHeight: device.channelHeight,
            applications: Device.current.applications)
            .toHttpResponse()
    }
}
