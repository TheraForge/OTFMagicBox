/*
 Copyright (c) 2025, Hippocrates Technologies Sagl. All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.

 3. Neither the name of the copyright holder(s) nor the names of any contributor(s) may
 be used to endorse or promote products derived from this software without specific
 prior written permission. No license is granted to the trademarks of the copyright
 holders even if such marks are included in this software.

 4. Commercial redistribution in any form requires an explicit license agreement with the
 copyright holder(s). Please contact support@hippocratestech.com for further information
 regarding licensing.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 OF SUCH DAMAGE.
 */

import Foundation

extension URLRequest {

    /// Returns a cURL command for a request
    /// - return A String object that contains cURL command or "" if an URL is not properly initalized.
    var cURL: String {

        guard
            let url = url,
            let httpMethod = httpMethod,
            !url.absoluteString.utf8.isEmpty
        else {
            return ""
        }

        var curlCommand = "curl --verbose \\\n"

        var diagnosticURL = url
        if var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           components.user != nil || components.password != nil {
            components.user = components.user == nil ? nil : "<redacted>"
            components.password = components.password == nil ? nil : "<redacted>"
            diagnosticURL = components.url ?? url
        }
        curlCommand = curlCommand.appendingFormat(" '%@' \\\n", diagnosticURL.absoluteString)

        // Method if different from GET
        if httpMethod != "GET" {
            curlCommand = curlCommand.appendingFormat(" -X %@ \\\n", httpMethod)
        }

        // Headers
        let sensitiveHeaderNames = Set([
            "authorization",
            "api-key",
            "cookie",
            "set-cookie"
        ])
        let allHeadersFields = allHTTPHeaderFields ?? [:]
        let allHeadersKeys = Array(allHeadersFields.keys)
        let sortedHeadersKeys  = allHeadersKeys.sorted(by: <)
        for key in sortedHeadersKeys {
            let value = sensitiveHeaderNames.contains(key.lowercased())
                ? "<redacted>"
                : self.value(forHTTPHeaderField: key) ?? ""
            curlCommand = curlCommand.appendingFormat(" -H '%@: %@' \\\n", key, value)
        }

        if let httpBody, !httpBody.isEmpty {
            curlCommand = curlCommand.appendingFormat(
                " --data '<redacted: %d bytes>' \\\n",
                httpBody.count
            )
        }
        return curlCommand
    }

    /// Escapes all single quotes for shell from a given string.
    static func escapeAllSingleQuotes(_ value: String) -> String {
        return value.replacingOccurrences(of: "'", with: "'\\''")
    }
}
