/*
 Copyright (c) 2024, Hippocrates Technologies Sagl. All rights reserved.
 
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
import OSLog
import Foundation

@available(iOS 15.0, *)
struct LogViewer: View {
    private let manager: LogManager?
    
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var selectedLogLevel: LogLevel = .all
    @State private var logs: [OSLogEntryLog] = []
    @State private var isLoading = false
    @State private var queryTask: Task<Void, Never>?
    @State private var showingAlert = false
    @State private var errorMessage = ""
    @State private var searchText = ""
    
    @State private var showingShareSheet = false
    
    private var filteredLogs: [OSLogEntryLog] {
        if searchText.isEmpty {
            return logs
        } else {
            return logs.filter { $0.composedMessage.contains(searchText) }
        }
    }
    
    var body: some View {
        VStack {
            if #available(iOS 17.0, *) {
                VStack {
                    Text(Constants.Logger.filterText)
                    DatePicker(Constants.Logger.startDate, selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    DatePicker(Constants.Logger.endDate, selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                    HStack {
                        Text(Constants.Logger.logLevel)
                        Spacer()
                        Picker(Constants.Logger.logLevel, selection: $selectedLogLevel) {
                            ForEach(LogLevel.allCases) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                    }
                }
                .padding()
            }
            
            if isLoading {
                Spacer()
                ProgressView(Constants.Logger.loaderText).padding()
                Spacer()
            } else {
                LogsListView(logs: filteredLogs)
            }
            Spacer()
        }
        .navigationTitle(Constants.Logger.navTitle)
        .onAppear {
            queryLogs()
        }
        .onChange(of: startDate) { _ in queryLogs() }
        .onChange(of: endDate) { _ in queryLogs() }
        .onChange(of: selectedLogLevel) { _ in queryLogs() }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: queryLogs) {
                    Image(systemName: "arrow.clockwise")
                }
                if !logs.isEmpty {
                    Button(action: shareLogs) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .alert(errorMessage, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        }
        .searchable(text: $searchText)
    }
    
    init() {
        do {
            self.manager = try LogManager()
        } catch {
            self.manager = nil
            displayError(message: error.localizedDescription)
        }
    }
    
    private func queryLogs() {
        guard let manager else { return }
        isLoading = true
        
        Task(priority: .background) {
            do {
                let fetchedLogs = try await manager.queryAsync(
                    startDate: startDate,
                    endDate: endDate,
                    logLevel: selectedLogLevel.osLogLevel
                )
                await MainActor.run {
                    logs = fetchedLogs
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func shareLogs() {
        let logsText = logs.formattedLogOutput()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(Constants.Logger.logFileName+".log")
        
        do {
            // Write logs to a temporary file
            try logsText.write(to: tempURL, atomically: true, encoding: .utf8)
            
            // Share the file
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            if let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
                .first {
                rootVC.present(activityVC, animated: true)
            } else {
                displayError(message: "Unable to present the share sheet.")
            }
        } catch {
            displayError(message: "Error writing to file: \(error.localizedDescription)")
        }
    }
    
    
    private func displayError(message: String) {
        errorMessage = message
        showingAlert = true
    }
}

@available(iOS 15.0, *)
extension Array where Element == OSLogEntryLog {
    func formattedLogOutput() -> String {
        self.map { entry in
            "[\(entry.date.formatted())] [\(entry.category)] [\(entry.level.rawValue)]: \(entry.composedMessage)"
        }
        .joined(separator: "\n")
    }
}
