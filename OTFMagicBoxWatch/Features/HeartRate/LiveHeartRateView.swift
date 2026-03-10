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

import SwiftUI

struct LiveHeartRateView: View {

    private enum FileConstants {
        static let heartSize: CGFloat = 50
        static let bpmFontSize: CGFloat = 48
        static let ringCount = 4
        static let baseRingScale: CGFloat = 0.4
        static let ringScaleStep: CGFloat = 0.25
    }

    @ObservedObject private var manager = LiveHeartRateManager.shared
    @State private var pulse = false

    var body: some View {
        NavigationStack {
            ZStack {
                pulsingRingsBackground

                VStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: FileConstants.heartSize))
                        .foregroundStyle(.red)
                        .scaleEffect(pulse ? 1.15 : 1.0)
                        .shadow(color: .red.opacity(0.6), radius: pulse ? 20 : 10)
                        .onTapGesture {
                            toggleSession()
                        }

                    VStack(spacing: 2) {
                        if manager.isRunning {
                            if manager.bpm > 0 {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("\(manager.bpm)")
                                        .font(.system(size: FileConstants.bpmFontSize, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)

                                    Text("BPM")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            } else {
                                Text("Measuring...")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Tap heart to start")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Heart Rate")
            .background(Color.black)
        }
        .onChange(of: manager.bpm) { _ in
            if manager.isRunning {
                startPulseAnimation()
            }
        }
        .onChange(of: manager.isRunning) { running in
            if running {
                startPulseAnimation()
            } else {
                stopPulseAnimation()
            }
        }
    }

    // MARK: - Pulsing Rings Background

    private var pulsingRingsBackground: some View {
        ZStack {
            ForEach(0..<FileConstants.ringCount, id: \.self) { index in
                let scale = FileConstants.baseRingScale + (CGFloat(index) * FileConstants.ringScaleStep)
                let opacity = 0.6 - (Double(index) * 0.12)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.red.opacity(opacity), .red.opacity(0.05)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .scaleEffect(pulse ? scale + 0.15 : scale)
                    .opacity(pulse ? opacity : opacity * 0.6)
                    .animation(
                        .easeInOut(duration: pulseDuration)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.08),
                        value: pulse
                    )
            }
        }
        .frame(width: 200, height: 200)
    }

    // MARK: - Actions

    private func toggleSession() {
        if manager.isRunning {
            manager.stop()
        } else {
            manager.start()
        }
    }

    private var pulseDuration: Double {
        let bpm = max(manager.bpm, 60)
        return 60.0 / Double(bpm) / 2
    }

    private func startPulseAnimation() {
        pulse = false
        withAnimation {
            pulse = true
        }
    }

    private func stopPulseAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            pulse = false
        }
    }
}

#Preview {
    LiveHeartRateView()
}
