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
enum ResearchKitTaskType: Codable {

    case audioTask(AudioTaskConfiguration)
    case fitnessCheck(FitnessCheckTaskConfiguration)
    case orderedTask(OrderedTaskConfiguration)
    case holePegTest(HolePegTestTaskConfiguration)
    case psat(PSATTaskConfiguration)
    case reactionTime(ReactionTimeTaskConfiguration)
    case shortWalk(ShortWalkTaskConfiguration)
    case spatialSpanMemory(SpatialSpanMemoryTaskConfiguration)
    case speechRecognition(SpeechRecognitionTaskConfiguration)
    case speechInNoise(SpeechInNoiseTaskConfiguration)
    case stroop(StroopTaskConfiguration)
    case timedWalk(TimedWalkTaskConfiguration)
    case toneAudiometry(ToneAudiometryTaskConfiguration)
    case dBHLToneAudiometry(DBHLToneAudiometryTaskConfiguration)
    case amslerGrid(AmslerGridTaskConfiguration)
    case towerOfHanoi(TowerOfHanoiTaskConfiguration)
    case twoFingerTappingInterval(TwoFingerTappingTaskConfiguration)
    case walkBackAndForth(WalkBackAndForthTaskConfiguration)
    case tremorTest(TremorTestTaskConfiguration)
    case kneeRangeOfMotion(KneeRangeOfMotionTaskConfiguration)
    case shoulderRangeOfMotion(ShoulderRangeOfMotionTaskConfiguration)
    case trailMaking(TrailMakingTaskConfiguration)
    case landoltCVisualAcuity(LandoltCVisualAcuityTaskConfiguration)
    case landoltCContrastSensitivity(LandoltCContrastSensitivityTaskConfiguration)
    case navigableOrderedTask(NavigableOrderedTaskConfiguration)

    private enum CaseKey: String, CodingKey {
        case audioTask
        case fitnessCheck
        case orderedTask
        case holePegTest
        case psat
        case reactionTime
        case shortWalk
        case spatialSpanMemory
        case speechRecognition
        case speechInNoise
        case stroop
        case timedWalk
        case toneAudiometry
        case dBHLToneAudiometry
        case amslerGrid
        case towerOfHanoi
        case twoFingerTappingInterval
        case walkBackAndForth
        case tremorTest
        case kneeRangeOfMotion
        case shoulderRangeOfMotion
        case trailMaking
        case landoltCVisualAcuity
        case landoltCContrastSensitivity
        case navigableOrderedTask
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
        case .audioTask:
            self = .audioTask(try container.decode(AudioTaskConfiguration.self, forKey: .audioTask))
        case .fitnessCheck:
            self = .fitnessCheck(try container.decode(FitnessCheckTaskConfiguration.self, forKey: .fitnessCheck))
        case .orderedTask:
            self = .orderedTask(try container.decode(OrderedTaskConfiguration.self, forKey: .orderedTask))
        case .holePegTest:
            self = .holePegTest(try container.decode(HolePegTestTaskConfiguration.self, forKey: .holePegTest))
        case .psat:
            self = .psat(try container.decode(PSATTaskConfiguration.self, forKey: .psat))
        case .reactionTime:
            self = .reactionTime(try container.decode(ReactionTimeTaskConfiguration.self, forKey: .reactionTime))
        case .shortWalk:
            self = .shortWalk(try container.decode(ShortWalkTaskConfiguration.self, forKey: .shortWalk))
        case .spatialSpanMemory:
            self = .spatialSpanMemory(try container.decode(SpatialSpanMemoryTaskConfiguration.self, forKey: .spatialSpanMemory))
        case .speechRecognition:
            self = .speechRecognition(try container.decode(SpeechRecognitionTaskConfiguration.self, forKey: .speechRecognition))
        case .speechInNoise:
            self = .speechInNoise(try container.decode(SpeechInNoiseTaskConfiguration.self, forKey: .speechInNoise))
        case .stroop:
            self = .stroop(try container.decode(StroopTaskConfiguration.self, forKey: .stroop))
        case .timedWalk:
            self = .timedWalk(try container.decode(TimedWalkTaskConfiguration.self, forKey: .timedWalk))
        case .toneAudiometry:
            self = .toneAudiometry(try container.decode(ToneAudiometryTaskConfiguration.self, forKey: .toneAudiometry))
        case .dBHLToneAudiometry:
            self = .dBHLToneAudiometry(try container.decode(DBHLToneAudiometryTaskConfiguration.self, forKey: .dBHLToneAudiometry))
        case .amslerGrid:
            self = .amslerGrid(try container.decode(AmslerGridTaskConfiguration.self, forKey: .amslerGrid))
        case .towerOfHanoi:
            self = .towerOfHanoi(try container.decode(TowerOfHanoiTaskConfiguration.self, forKey: .towerOfHanoi))
        case .twoFingerTappingInterval:
            self = .twoFingerTappingInterval(try container.decode(TwoFingerTappingTaskConfiguration.self, forKey: .twoFingerTappingInterval))
        case .walkBackAndForth:
            self = .walkBackAndForth(try container.decode(WalkBackAndForthTaskConfiguration.self, forKey: .walkBackAndForth))
        case .tremorTest:
            self = .tremorTest(try container.decode(TremorTestTaskConfiguration.self, forKey: .tremorTest))
        case .kneeRangeOfMotion:
            self = .kneeRangeOfMotion(try container.decode(KneeRangeOfMotionTaskConfiguration.self, forKey: .kneeRangeOfMotion))
        case .shoulderRangeOfMotion:
            self = .shoulderRangeOfMotion(try container.decode(ShoulderRangeOfMotionTaskConfiguration.self, forKey: .shoulderRangeOfMotion))
        case .trailMaking:
            self = .trailMaking(try container.decode(TrailMakingTaskConfiguration.self, forKey: .trailMaking))
        case .landoltCVisualAcuity:
            self = .landoltCVisualAcuity(try container.decode(LandoltCVisualAcuityTaskConfiguration.self, forKey: .landoltCVisualAcuity))
        case .landoltCContrastSensitivity:
            self = .landoltCContrastSensitivity(try container.decode(LandoltCContrastSensitivityTaskConfiguration.self, forKey: .landoltCContrastSensitivity))
        case .navigableOrderedTask:
            self = .navigableOrderedTask(try container.decode(NavigableOrderedTaskConfiguration.self, forKey: .navigableOrderedTask))
        }
    }
}

extension ResearchKitTaskType {

    var task: ORKTask {
        switch self {

        case .audioTask(let config):
            config.task
        case .fitnessCheck(let config):
            config.task
        case .orderedTask(let config):
            config.task
        case .holePegTest(let config):
            config.task
        case .psat(let config):
            config.task
        case .reactionTime(let config):
            config.task
        case .shortWalk(let config):
            config.task
        case .spatialSpanMemory(let config):
            config.task
        case .speechRecognition(let config):
            config.task
        case .speechInNoise(let config):
            config.task
        case .stroop(let config):
            config.task
        case .timedWalk(let config):
            config.task
        case .toneAudiometry(let config):
            config.task
        case .dBHLToneAudiometry(let config):
            config.task
        case .amslerGrid(let config):
            config.task
        case .towerOfHanoi(let config):
            config.task
        case .twoFingerTappingInterval(let config):
            config.task
        case .walkBackAndForth(let config):
            config.task
        case .tremorTest(let config):
            config.task
        case .kneeRangeOfMotion(let config):
            config.task
        case .shoulderRangeOfMotion(let config):
            config.task
        case .trailMaking(let config):
            config.task
        case .landoltCVisualAcuity(let config):
            config.task
        case .landoltCContrastSensitivity(let config):
            config.task
        case .navigableOrderedTask(let config):
            config.task
        }
    }
}
