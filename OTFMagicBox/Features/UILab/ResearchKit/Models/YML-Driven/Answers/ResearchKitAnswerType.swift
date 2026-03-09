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
import UIKit
import OTFTemplateBox
import OTFResearchKit
import RawModel

@RawGenerable
enum ResearchKitAnswerType: Codable {

    case boolean(BooleanAnswerFormatConfiguration)
    case dateFormat(DateFormatConfiguration)
    case scale(ScaleFormatConfiguration)
    case continuousScale(ContinuousScaleFormatConfiguration)
    case textScale(TextScaleFormatConfiguration)
    case textChoiceAnswer(TextChoiceAnswerFormatConfiguration)
    case imageChoiceAnswer(ImageChoiceAnswerFormatConfiguration)
    case email(EmailAnswerFormatConfiguration)
    case text(TextAnswerFormatConfiguration)
    case valuePicker(ValuePickerAnswerFormatConfiguration)
    case location(LocationAnswerFormatConfiguration)
    case timeInterval(TimeIntervalAnswerFormatConfiguration)
    case timeOfDay(TimeOfDayAnswerFormatConfiguration)
    case decimal(DecimalAnswerFormatConfiguration)
    case integer(IntegerAnswerFormatConfiguration)
    case socioEconomic(SESAnswerFormatConfiguration)

    private enum CaseKey: String, CodingKey {
        case boolean
        case dateFormat
        case scale
        case continuousScale
        case textScale
        case textChoiceAnswer
        case imageChoiceAnswer
        case email
        case text
        case valuePicker
        case location
        case timeInterval
        case timeOfDay
        case decimal
        case integer
        case socioEconomic
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CaseKey.self)
        let keys = container.allKeys
        guard keys.count == 1, let key = keys.first else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: container.codingPath,
                debugDescription: "Expected exactly one ResearchKitAnswerType key, found \(keys.count)"
            ))
        }
        switch key {
        case .boolean:
            self = .boolean(try container.decode(BooleanAnswerFormatConfiguration.self, forKey: .boolean))
        case .dateFormat:
            self = .dateFormat(try container.decode(DateFormatConfiguration.self, forKey: .dateFormat))
        case .scale:
            self = .scale(try container.decode(ScaleFormatConfiguration.self, forKey: .scale))
        case .continuousScale:
            self = .continuousScale(try container.decode(ContinuousScaleFormatConfiguration.self, forKey: .continuousScale))
        case .textScale:
            self = .textScale(try container.decode(TextScaleFormatConfiguration.self, forKey: .textScale))
        case .textChoiceAnswer:
            self = .textChoiceAnswer(try container.decode(TextChoiceAnswerFormatConfiguration.self, forKey: .textChoiceAnswer))
        case .imageChoiceAnswer:
            self = .imageChoiceAnswer(try container.decode(ImageChoiceAnswerFormatConfiguration.self, forKey: .imageChoiceAnswer))
        case .email:
            self = .email(try container.decode(EmailAnswerFormatConfiguration.self, forKey: .email))
        case .text:
            self = .text(try container.decode(TextAnswerFormatConfiguration.self, forKey: .text))
        case .valuePicker:
            self = .valuePicker(try container.decode(ValuePickerAnswerFormatConfiguration.self, forKey: .valuePicker))
        case .location:
            self = .location(try container.decode(LocationAnswerFormatConfiguration.self, forKey: .location))
        case .timeInterval:
            self = .timeInterval(try container.decode(TimeIntervalAnswerFormatConfiguration.self, forKey: .timeInterval))
        case .timeOfDay:
            self = .timeOfDay(try container.decode(TimeOfDayAnswerFormatConfiguration.self, forKey: .timeOfDay))
        case .decimal:
            self = .decimal(try container.decode(DecimalAnswerFormatConfiguration.self, forKey: .decimal))
        case .integer:
            self = .integer(try container.decode(IntegerAnswerFormatConfiguration.self, forKey: .integer))
        case .socioEconomic:
            self = .socioEconomic(try container.decode(SESAnswerFormatConfiguration.self, forKey: .socioEconomic))
        }
    }
}

extension ResearchKitAnswerType {

    var answerFormat: ORKAnswerFormat {

        switch self {

        case .boolean(let booleanFormat):
            booleanFormat.answerFormat
        case .dateFormat(let dateFormat):
            dateFormat.answerFormat
        case .scale(let scaleFormat):
            scaleFormat.answerFormat
        case .continuousScale(let continuousScale):
            continuousScale.answerFormat
        case .textScale(let textScale):
            textScale.answerFormat
        case .textChoiceAnswer(let choice):
            choice.answerFormat
        case .imageChoiceAnswer(let imageChoice):
            imageChoice.answerFormat
        case .email(let emailConfig):
            emailConfig.answerFormat
        case .text(let textConfig):
            textConfig.answerFormat
        case .valuePicker(let valuePickerConfig):
            valuePickerConfig.answerFormat
        case .location(let locationConfig):
            locationConfig.answerFormat
        case .timeInterval(let timeIntervalConfig):
            timeIntervalConfig.answerFormat
        case .timeOfDay(let timeOfDayConfig):
            timeOfDayConfig.answerFormat
        case .decimal(let decimalConfig):
            decimalConfig.answerFormat
        case .integer(let integerConfig):
            integerConfig.answerFormat
        case .socioEconomic(let sesConfig):
            sesConfig.answerFormat
        }
    }
}
