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
import OTFTemplateBox
import RawModel

@RawGenerable
struct LogConfiguration: Codable {
    let version: String
    let featureTitle: OTFStringLocalized
    let navTitle: OTFStringLocalized
    let emptyTitle: OTFStringLocalized
    let emptySubtitle: OTFStringLocalized
    let filterLabel: OTFStringLocalized
    let startLabel: OTFStringLocalized
    let endLabel: OTFStringLocalized
    let levelLabel: OTFStringLocalized
    let detailTitle: OTFStringLocalized
    let dateLabel: OTFStringLocalized
    let categoryLabel: OTFStringLocalized
    let subsystemLabel: OTFStringLocalized
    let searchPlaceholder: OTFStringLocalized
    let refreshTitle: OTFStringLocalized
    let exportTitle: OTFStringLocalized
    let copyTitle: OTFStringLocalized
    let rowsMaxLines: Int
    let defaultDaysBack: Int
}

extension LogConfiguration: OTFVersionedDecodable {
    typealias Raw = RawLogConfiguration

    static let fallback = LogConfiguration(
        version: "1.0.0",
        featureTitle: "Diagnostics",
        navTitle: "Logs",
        emptyTitle: "No logs found",
        emptySubtitle: "Try widening the date range or choosing another level.",
        filterLabel: "Filter",
        startLabel: "Start",
        endLabel: "End",
        levelLabel: "Level",
        detailTitle: "Entry",
        dateLabel: "Date",
        categoryLabel: "Category",
        subsystemLabel: "Subsystem",
        searchPlaceholder: "Search message, category or subsystem",
        refreshTitle: "Refresh",
        exportTitle: "Export",
        copyTitle: "Copy",
        rowsMaxLines: 3,
        defaultDaysBack: 1
    )

    init(from raw: RawLogConfiguration) {
        let fallback = Self.fallback
        self.version = raw.version ?? fallback.version
        self.featureTitle = raw.featureTitle ?? fallback.featureTitle
        self.navTitle = raw.navTitle ?? fallback.navTitle
        self.emptyTitle = raw.emptyTitle ?? fallback.emptyTitle
        self.emptySubtitle = raw.emptySubtitle ?? fallback.emptySubtitle
        self.filterLabel = raw.filterLabel ?? fallback.filterLabel
        self.startLabel = raw.startLabel ?? fallback.startLabel
        self.endLabel = raw.endLabel ?? fallback.endLabel
        self.levelLabel = raw.levelLabel ?? fallback.levelLabel
        self.detailTitle = raw.detailTitle ?? fallback.detailTitle
        self.dateLabel = raw.dateLabel ?? fallback.dateLabel
        self.categoryLabel = raw.categoryLabel ?? fallback.categoryLabel
        self.subsystemLabel = raw.subsystemLabel ?? fallback.subsystemLabel
        self.searchPlaceholder = raw.searchPlaceholder ?? fallback.searchPlaceholder
        self.refreshTitle = raw.refreshTitle ?? fallback.refreshTitle
        self.exportTitle = raw.exportTitle ?? fallback.exportTitle
        self.copyTitle = raw.copyTitle ?? fallback.copyTitle
        self.rowsMaxLines = raw.rowsMaxLines ?? fallback.rowsMaxLines
        self.defaultDaysBack = raw.defaultDaysBack ?? fallback.defaultDaysBack
    }

    static func migrate(from version: OTFSemanticVersion, raw: RawLogConfiguration) throws -> LogConfiguration {
        LogConfiguration(from: raw)
    }
}
