/*
 Copyright (c) 2026, Hippocrates Technologies Sagl. All rights reserved.

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
import OTFCareKit
import OTFCareKitStore
import OTFCareKitUI

final class SensorTaskViewSynchronizer: OCKTaskViewSynchronizerProtocol {

    typealias View = SensorTaskContainerView

    private let metric: HealthKitDataManager.HealthMetric
    private let selectedDate: Date
    private let storeManager: OCKSynchronizedStoreManager

    init(metric: HealthKitDataManager.HealthMetric, selectedDate: Date, storeManager: OCKSynchronizedStoreManager) {
        self.metric = metric
        self.selectedDate = selectedDate
        self.storeManager = storeManager
    }

    func makeView() -> SensorTaskContainerView {
        SensorTaskContainerView()
    }

    func updateView(_ view: SensorTaskContainerView, context: OCKSynchronizationContext<OCKTaskEvents>) {
        let task = context.viewModel.tasks.first
        let events = context.viewModel.first ?? []
        let hasSentOutcome = events.contains { $0.outcome != nil }
        let sentValueText = outcomeValueText(from: events)
        let eventIndexPath = events.isEmpty ? nil : IndexPath(row: 0, section: 0)
        view.update(
            task: task,
            hasSentOutcome: hasSentOutcome,
            sentValueText: sentValueText,
            eventIndexPath: eventIndexPath,
            metric: metric,
            selectedDate: selectedDate,
            storeManager: storeManager
        )
    }

    private func outcomeValueText(from events: [OCKAnyEvent]) -> String? {
        guard let outcomeValue = events.first?.outcome?.values.first else { return nil }
        let valueText = formatOutcomeValue(outcomeValue)
        guard !valueText.isEmpty else { return nil }
        let format = SensorTaskConfigurationLoader.config.sentValueFormat.localized
        return String(format: format, valueText)
    }

    private func formatOutcomeValue(_ value: OCKOutcomeValue) -> String {

        if let number = value.doubleValue {
            let formatted = MetricFormatter.format(number, decimals: 0)
            return joinValueAndUnits(valueText: formatted, units: value.units)
        }
        if let number = value.integerValue {
            return joinValueAndUnits(valueText: "\(number)", units: value.units)
        }
        if let text = value.stringValue {
            return joinValueAndUnits(valueText: text, units: value.units)
        }
        return joinValueAndUnits(valueText: value.description, units: value.units)
    }

    private func joinValueAndUnits(valueText: String, units: String?) -> String {
        guard let units, !units.isEmpty else { return valueText }
        return "\(valueText) \(units)"
    }
}
