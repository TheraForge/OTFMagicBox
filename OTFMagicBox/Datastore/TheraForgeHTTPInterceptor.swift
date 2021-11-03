//
//  TheraForgeHTTPInterceptor.swift
//  OTFMagicBox
//
//  Created by Admin on 02/11/2021.
//

import OTFCDTDatastore
import OTFCloudClientAPI

class TheraForgeHTTPInterceptor: NSObject, CDTHTTPInterceptor {

    func interceptRequest(in context: CDTHTTPInterceptorContext) -> CDTHTTPInterceptorContext? {
        if let currentAuth = TheraForgeNetwork.shared.currentAuth {
            context.request.setValue("\(TheraForgeNetwork.shared.identifierForVendor)",
                                     forHTTPHeaderField: "Client")
            context.request.setValue("Bearer \(currentAuth.token)", forHTTPHeaderField: "Authorization")
            context.request.addValue("\(TheraForgeNetwork.configurations!.apiKey)",
                                     forHTTPHeaderField: "API-KEY")
        }
        return context
    }

    func interceptResponse(in context: CDTHTTPInterceptorContext) -> CDTHTTPInterceptorContext? {
        NSLog("TheraForgeHTTPInterceptor: \n\n\((context.request as URLRequest).cURL)")
        guard let response = context.response else {
            NSLog("TheraForgeHTTPInterceptor: Response is nil")
            return context
        }
        
        guard let responseData = context.responseData else {
            NSLog("TheraForgeHTTPInterceptor: Response data is nil")
            return context
        }
        
        NSLog("TheraForgeHTTPInterceptor: \n\n\(context.request)\n\n\(String(describing: response))\n\ndata: \(String(data: responseData, encoding: .utf8)!)")
        return context
    }

}
