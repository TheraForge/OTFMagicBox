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

import OTFUtilities
import OTFTemplateBox
import RawModel

@RawGenerable
struct StaticContact: Codable {

    let version: String
    let name: String
    let surname: String
    let asset: String
    let role: OTFStringLocalized
    let title: String
    let email: String
    let phoneNumber: String
    @NestedRaw let address: StaticAddress

    var id: String {
        name + "" + surname
    }
}

extension StaticContact: OTFVersionedDecodable {
    typealias Raw = RawStaticContact

    static let fallback = StaticContact(
        version: "2.0.0",
        name: "John",
        surname: "Doe",
        asset: "janne",
        role: "Ophthalmologist",
        title: "Dr. john Doe",
        email: "doctor@johndoe.com",
        phoneNumber: "(351) 1234-1234",
        address: StaticAddress.fallback)

    init(from raw: RawStaticContact) {
        let fallback = Self.fallback
        self.version = raw.version ?? fallback.version
        self.name = raw.name ?? fallback.name
        self.surname = raw.surname ?? fallback.surname
        self.asset = raw.asset ?? fallback.asset
        self.role = raw.role ?? fallback.role
        self.title = raw.title ?? fallback.title
        self.email = raw.email ?? fallback.email
        self.phoneNumber = raw.phoneNumber ?? fallback.phoneNumber

        let decoded = raw.address.map { StaticAddress(from: $0) }
        self.address = decoded ?? fallback.address
    }

    static func migrate(from version: OTFSemanticVersion, raw: RawStaticContact) throws -> StaticContact {
        StaticContact(from: raw)
    }
}

@RawGenerable
struct StaticAddress: Codable {
    let street: String
    let city: String
    let postalCode: String
    let state: String

    static let fallback = StaticAddress(street: "Test Street", city: "Test City", postalCode: "12345", state: "Test State")
}

extension StaticAddress {
    init(from raw: RawStaticAddress) {
        let fallback = Self.fallback
        self.street = raw.street ?? fallback.street
        self.city = raw.city ?? fallback.city
        self.postalCode = raw.postalCode ?? fallback.postalCode
        self.state = raw.state ?? fallback.state
    }
}
