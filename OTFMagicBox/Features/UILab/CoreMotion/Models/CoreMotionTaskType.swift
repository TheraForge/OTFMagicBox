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

import SwiftUI
import OTFCareKit
import OTFCareKitStore

enum CoreMotionTaskType: String, CaseIterable, Identifiable {

    case steps, cadence, balance, accelerometer, gyroscope, gps

    var id: String { rawValue }

    var title: String {
        let config = MotionConfigurationViewModel.shared.config
        return switch self {
        case .steps: config.titleSteps.localized
        case .cadence: config.titleCadence.localized
        case .balance: config.titleBalance.localized
        case .accelerometer: config.titleAccelerometer.localized
        case .gyroscope: config.titleGyroscope.localized
        case .gps: config.titleGPS.localized
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .steps:
            CoreMotionContainerView(title: title) {
                MotionStepsCard(
                    task: Self.stepsTask(),
                    eventQuery: PreviewFactory.eventQuery,
                    storeManager: PreviewFactory.storeManager,
                    selectedDate: PreviewFactory.date
                )
            }
        case .cadence:
            CoreMotionContainerView(title: title) {
                MotionCadenceCard(
                    task: Self.cadenceTask(),
                    eventQuery: PreviewFactory.eventQuery,
                    storeManager: PreviewFactory.storeManager,
                    selectedDate: PreviewFactory.date
                )
            }
        case .balance:
            CoreMotionContainerView(title: title) {
                MotionBalanceCard(
                    task: Self.balanceTask(),
                    eventQuery: PreviewFactory.eventQuery,
                    storeManager: PreviewFactory.storeManager,
                    selectedDate: PreviewFactory.date
                )
            }
        case .accelerometer:
            CoreMotionContainerView(title: title) {
                MotionAccelerometerCard(
                    task: Self.accelerometerTask(),
                    eventQuery: PreviewFactory.eventQuery,
                    storeManager: PreviewFactory.storeManager,
                    selectedDate: PreviewFactory.date
                )
            }
        case .gyroscope:
            CoreMotionContainerView(title: title) {
                MotionGyroscopeCard(
                    task: Self.gyroscopeTask(),
                    eventQuery: PreviewFactory.eventQuery,
                    storeManager: PreviewFactory.storeManager,
                    selectedDate: PreviewFactory.date
                )
            }
        case .gps:
            CoreMotionContainerView(title: title) {
                MotionGPSCard(
                    task: Self.gpsTask(),
                    eventQuery: PreviewFactory.eventQuery,
                    storeManager: PreviewFactory.storeManager,
                    selectedDate: PreviewFactory.date
                )
            }
        }
    }
}

// MARK: - Motion-themed tasks
extension CoreMotionTaskType {

    static func stepsTask() -> OCKAnyTask {
        let config = MotionConfigurationViewModel.shared.config
        var task = OCKTask(id: "motion.steps", title: config.titleSteps.localized, carePlanUUID: nil, schedule: scheduleTwoTimesPerDay())
        task.instructions = config.instructionsSteps.localized
        return task
    }

    static func balanceTask() -> OCKAnyTask {
        let config = MotionConfigurationViewModel.shared.config
        var task = OCKTask(id: "motion.balance", title: config.titleBalance.localized, carePlanUUID: nil, schedule: scheduleTwoTimesPerDay())
        task.instructions = config.instructionsBalance.localized
        return task
    }

    static func cadenceTask() -> OCKAnyTask {
        let config = MotionConfigurationViewModel.shared.config
        var task = OCKTask(id: "motion.cadence", title: config.titleCadence.localized, carePlanUUID: nil, schedule: scheduleTwoTimesPerDay())
        task.instructions = config.instructionsCadence.localized
        return task
    }

    static func accelerometerTask() -> OCKAnyTask {
        let config = MotionConfigurationViewModel.shared.config
        var task = OCKTask(id: "sensor.accel", title: config.titleAccelerometer.localized, carePlanUUID: nil, schedule: scheduleTwoTimesPerDay())
        task.instructions = config.instructionsAccelerometer.localized
        return task
    }

    static func gyroscopeTask() -> OCKAnyTask {
        let config = MotionConfigurationViewModel.shared.config
        var task = OCKTask(id: "sensor.gyro", title: config.titleGyroscope.localized, carePlanUUID: nil, schedule: scheduleTwoTimesPerDay())
        task.instructions = config.instructionsGyroscope.localized
        return task
    }

    static func gpsTask() -> OCKAnyTask {
        let config = MotionConfigurationViewModel.shared.config
        var task = OCKTask(id: "sensor.gps", title: config.titleGPS.localized, carePlanUUID: nil, schedule: scheduleTwoTimesPerDay())
        task.instructions = config.instructionsGPS.localized
        return task
    }
}

// MARK: - Helper functions

private extension CoreMotionTaskType {

    static func scheduleTwoTimesPerDay(startDaysAgo: Int = 4, hours: (Int, Int) = (8, 14), everyDays: (Int, Int) = (1, 2)) -> OCKSchedule {
        let todayStart = PreviewFactory.cal.startOfDay(for: PreviewFactory.date)
        let aFewDaysAgo = PreviewFactory.cal.date(byAdding: .day, value: -startDaysAgo, to: todayStart)!

        let before = PreviewFactory.cal.date(byAdding: .hour, value: hours.0, to: aFewDaysAgo)!
        let after  = PreviewFactory.cal.date(byAdding: .hour, value: hours.1, to: aFewDaysAgo)!

        let morning = OCKScheduleElement(start: before, end: nil, interval: DateComponents(day: everyDays.0))
        let afternoon = OCKScheduleElement(start: after, end: nil, interval: DateComponents(day: everyDays.1))
        return OCKSchedule(composing: [morning, afternoon])
    }
}
