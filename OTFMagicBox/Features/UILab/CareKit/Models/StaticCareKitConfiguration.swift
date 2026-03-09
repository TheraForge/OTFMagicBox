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

import RawModel
import OTFTemplateBox

@RawGenerable
struct StaticCareKitConfiguration {

    let version: String
    @NestedRaw let contact: StaticContact
    @NestedRaw let task: StaticTask
    @NestedRaw let numericProgress: StaticNumericProgress
    @NestedRaw let labeledValue: StaticLabeledValue
}

extension StaticCareKitConfiguration: OTFVersionedDecodable {
    typealias Raw = RawStaticCareKitConfiguration

    static let fallback = StaticCareKitConfiguration(
        version: "2.0.0",
        contact: .fallback,
        task: .fallback,
        numericProgress: .fallback,
        labeledValue: .fallback
    )

    init(from raw: RawStaticCareKitConfiguration) {
        let fallback = Self.fallback
        self.version = raw.version ?? fallback.version
        self.contact = raw.contact.map(StaticContact.init(from:)) ?? fallback.contact
        self.task = raw.task.map(StaticTask.init(from:)) ?? fallback.task
        self.numericProgress = raw.numericProgress.map(StaticNumericProgress.init(from:)) ?? fallback.numericProgress
        self.labeledValue = raw.labeledValue.map(StaticLabeledValue.init(from:)) ?? fallback.labeledValue
    }

    static func migrate(from version: OTFSemanticVersion, raw: RawStaticCareKitConfiguration) throws -> StaticCareKitConfiguration {
        StaticCareKitConfiguration(from: raw)
    }
}
