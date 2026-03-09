/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2015-2016, Ricardo Sánchez-Sáez.
 Copyright (c) 2017, Macro Yau.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import OTFResearchKit
import HealthKit
import UIKit

extension StaticTaskOption {
    /// This task presents the Audio pre-defined active task.
    var audioTask: ORKTask {
        return ORKOrderedTask.audioTask(
            withIdentifier: "audioTask",
            intendedUseDescription: exampleDescription,
            speechInstruction: exampleSpeechInstruction,
            shortSpeechInstruction: exampleSpeechInstruction,
            duration: 20,
            recordingSettings: nil,
            checkAudioLevel: true,
            options: [])
    }
    
    /**
     This task presents the Fitness pre-defined active task. For this example,
     short walking and rest durations of 20 seconds each are used, whereas more
     realistic durations might be several minutes each.
     */
    var fitnessTask: ORKTask {
        return ORKOrderedTask.fitnessCheck(withIdentifier: "fitnessTask", intendedUseDescription: exampleDescription, walkDuration: 20, restDuration: 20, options: [])
    }
    
    /// This task presents the Hole Peg Test pre-defined active task.
    var holePegTestTask: ORKTask {
        return ORKNavigableOrderedTask.holePegTest(
            withIdentifier: "holePegTestTask",
            intendedUseDescription: exampleDescription,
            dominantHand: .right,
            numberOfPegs: 9,
            threshold: 0.2,
            rotated: false,
            timeLimit: 300,
            options: [])
    }
    
    /// This task presents the PSAT pre-defined active task.
    var PSATTask: ORKTask {
        return ORKOrderedTask.psatTask(
            withIdentifier: "psatTask",
            intendedUseDescription: exampleDescription,
            presentationMode: ORKPSATPresentationMode.auditory.union(.visual),
            interStimulusInterval: 3.0,
            stimulusDuration: 1.0,
            seriesLength: 60,
            options: [])
    }
    
    /// This task presents the Reaction Time pre-defined active task.
    var reactionTimeTask: ORKTask {
        /// An example of a custom sound.
        let successSoundURL = Bundle.main.url(forResource: "tap", withExtension: "aif")!
        let successSound = SystemSound(soundURL: successSoundURL)!
        return ORKOrderedTask.reactionTime(
            withIdentifier: "reactionTime",
            intendedUseDescription: exampleDescription,
            maximumStimulusInterval: 10,
            minimumStimulusInterval: 4,
            thresholdAcceleration: 0.5,
            numberOfAttempts: 3,
            timeout: 3,
            successSound: successSound.soundID,
            timeoutSound: 0,
            failureSound: UInt32(kSystemSoundID_Vibrate), options: [])
    }
    
    /// This task presents the Gait and Balance pre-defined active task.
    var shortWalkTask: ORKTask {
        return ORKOrderedTask.shortWalk(
            withIdentifier: "shortWalkTask",
            intendedUseDescription: exampleDescription,
            numberOfStepsPerLeg: 20,
            restDuration: 20,
            options: [])
    }
    
    /// This task presents the Spatial Span Memory pre-defined active task.
    var spatialSpanMemoryTask: ORKTask {
        return ORKOrderedTask.spatialSpanMemoryTask(
            withIdentifier: "spatialSpanMemoryTask",
            intendedUseDescription: exampleDescription,
            initialSpan: 3,
            minimumSpan: 2,
            maximumSpan: 15,
            playSpeed: 1.0,
            maximumTests: 5,
            maximumConsecutiveFailures: 3,
            customTargetImage: nil,
            customTargetPluralName: nil,
            requireReversal: false,
            options: [])
    }
    
    /// This task presents the Speech Recognition pre-defined active task.
    var speechRecognitionTask: ORKTask {
        return ORKOrderedTask.speechRecognitionTask(
            withIdentifier: "speechRecognitionTask",
            intendedUseDescription: exampleDescription,
            speechRecognizerLocale: .englishUS,
            speechRecognitionImage: nil,
            speechRecognitionText: NSLocalizedString("A quick brown fox jumps over the lazy dog.", comment: ""),
            shouldHideTranscript: false,
            allowsEdittingTranscript: true,
            options: [])
    }
    
    /// This task presents the Speech in Noise pre-defined active task.
    var speechInNoiseTask: ORKTask {
        return ORKOrderedTask.speechInNoiseTask(withIdentifier: "speechInNoiseTask", intendedUseDescription: nil, options: [])
    }
    
    /// This task presents the Stroop pre-defined active task.
    var stroopTask: ORKTask {
        return ORKOrderedTask.stroopTask(withIdentifier: "stroopTask", intendedUseDescription: exampleDescription, numberOfAttempts: 10, options: [])
    }
    
    /// This task presents the swift Stroop pre-defined active task.
    var swiftStroopTask: ORKTask {
        let instructionStep = ORKInstructionStep(identifier: "stroopInstructionStep")
        instructionStep.title = "Stroop"
        instructionStep.text = "Your description goes here."
        instructionStep.image = UIImage(named: "stroop")
        instructionStep.imageContentMode = .center
        instructionStep.detailText = "Every time a word appears, select the first letter of the name of the COLOR that is shown."

        let instructionStep2 = ORKInstructionStep(identifier: "stroopInstructionStep2")
        instructionStep2.title = "Stroop"
        instructionStep2.text = "Your description goes here."
        instructionStep2.detailText = "Every time a word appears, select the first letter of the name of the COLOR that is shown."
        instructionStep2.image = UIImage(named: "stroop")
        instructionStep2.imageContentMode = .center
        let countdownStep = ORKCountdownStep(identifier: "stroopCountdownStep")
        countdownStep.title = "Stroop"
        let stroopStep = ORKSwiftStroopStep(identifier: "stroopStep")
        stroopStep.numberOfAttempts = 10
        stroopStep.title = "Stroop"
        stroopStep.text = "Select the first letter of the name of the COLOR that is shown."
        stroopStep.spokenInstruction = stroopStep.text
        let completionStep = ORKCompletionStep(identifier: "stroopCompletionStep")
        completionStep.title = "Activity Complete"
        completionStep.text = "Your data will be analyzed and you will be notified when your results are ready."

        return ORKOrderedTask(identifier: "stroopTask", steps: [instructionStep, instructionStep2, countdownStep, stroopStep, completionStep])
    }
    
    /// This task presents the Timed Walk with turn around pre-defined active task.
    var timedWalkWithTurnAroundTask: ORKTask {
        return ORKOrderedTask.timedWalk(
            withIdentifier: "timedWalkWithTurnAroundTask",
            intendedUseDescription: exampleDescription,
            distanceInMeters: 100.0,
            timeLimit: 180.0,
            turnAroundTimeLimit: 60.0,
            includeAssistiveDeviceForm: true,
            options: [])
    }
    
    /// This task presents the Tone Audiometry pre-defined active task.
    var toneAudiometryTask: ORKTask {
        return ORKOrderedTask.toneAudiometryTask(
            withIdentifier: "toneAudiometryTask",
            intendedUseDescription: exampleDescription,
            speechInstruction: nil,
            shortSpeechInstruction: nil,
            toneDuration: 20,
            options: [])
    }
    
    /// This task presents the dBHL Tone Audiometry pre-defined active task.
    var dBHLToneAudiometryTask: ORKTask {
        return ORKOrderedTask.dBHLToneAudiometryTask(withIdentifier: "dBHLToneAudiometryTask", intendedUseDescription: nil, options: [])
    }
    
    /// This task presents the environment spl meter step.
    var splMeterTask: ORKTask {
        let splMeterStep = ORKEnvironmentSPLMeterStep(identifier: "splMeterStep")
        splMeterStep.samplingInterval = 2
        splMeterStep.requiredContiguousSamples = 10
        splMeterStep.thresholdValue = 60
        splMeterStep.title = NSLocalizedString("SPL Meter", comment: "")
        return ORKOrderedTask(identifier: "splMeterTask", steps: [splMeterStep])
    }
    
    var amslerGridTask: ORKTask {
        return ORKOrderedTask.amslerGridTask(withIdentifier: "amslerGridTask", intendedUseDescription: exampleDescription, options: [])
    }
    
    var towerOfHanoiTask: ORKTask {
        return ORKOrderedTask.towerOfHanoiTask(withIdentifier: "towerOfHanoi", intendedUseDescription: exampleDescription, numberOfDisks: 5, options: [])
    }
    
    /// This task presents the Two Finger Tapping pre-defined active task.
    var twoFingerTappingIntervalTask: ORKTask {
        return ORKOrderedTask.twoFingerTappingIntervalTask(
            withIdentifier: "twoFingerTappingIntervalTask",
            intendedUseDescription: exampleDescription,
            duration: 10, handOptions: [.both],
            options: []
        )
    }
    
    /// This task presents a walk back-and-forth task
    var walkBackAndForthTask: ORKTask {
        return ORKOrderedTask.walkBackAndForthTask(
            withIdentifier: "walkBackAndForthTask",
            intendedUseDescription: exampleDescription,
            walkDuration: 30,
            restDuration: 30,
            options: [])
    }
    
    /// This task presents the Tremor Test pre-defined active task.
    var tremorTestTask: ORKTask {
        return ORKOrderedTask.tremorTest(withIdentifier: "tremorTestTask",
                                         intendedUseDescription: exampleDescription,
                                         activeStepDuration: 10,
                                         activeTaskOptions: [],
                                         handOptions: [.both],
                                         options: [])
    }
    
    /// This task presents a knee range of motion task
    var kneeRangeOfMotion: ORKTask {
        return ORKOrderedTask.kneeRangeOfMotionTask(withIdentifier: "kneeRangeOfMotion", limbOption: .right, intendedUseDescription: exampleDescription, options: [])
    }
    
    /// This task presents a shoulder range of motion task
    var shoulderRangeOfMotion: ORKTask {
        return ORKOrderedTask.shoulderRangeOfMotionTask(
            withIdentifier: "shoulderRangeOfMotion",
            limbOption: .left,
            intendedUseDescription: exampleDescription,
            options: [])
    }
    
    /// This task presents a trail making task
    var trailMaking: ORKTask {
        let intendedUseDescription = "Tests visual attention and task switching"
        return ORKOrderedTask.trailmakingTask(
            withIdentifier: "trailMaking",
            intendedUseDescription: intendedUseDescription,
            trailmakingInstruction: nil,
            trailType: .B,
            options: [])
    }
    
    // This task presents a visual acuity landolt C task
    var visualAcuityLandoltC: ORKTask {
        let orderedTask = ORKOrderedTask.landoltCVisualAcuityTask(withIdentifier: "visualAcuityLandoltC", intendedUseDescription: "lorem ipsum")
        return orderedTask
    }
    
    // This task presents a contrast sensitivity peak landolt C task
    var contrastSensitivityPeakLandoltC: ORKTask {
        let orderedTask = ORKOrderedTask.landoltCContrastSensitivityTask(withIdentifier: "contrastSensitivityPeakLandoltC", intendedUseDescription: "lorem ipsum")
        return orderedTask
    }
}
