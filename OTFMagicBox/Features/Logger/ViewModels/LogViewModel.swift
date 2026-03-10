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
import Combine
import OTFTemplateBox
import OTFUtilities
import OSLog

@MainActor
final class LogViewModel: ObservableObject {

    private enum FileConstants {
        static let fileName: String = "LogConfiguration"
    }

    // MARK: - Publishers

    @Published var startDate: Date
    @Published var endDate: Date
    @Published var level: OSLogEntryLog.Level = .undefined
    @Published var search = ""
    @Published var alertMessage = ""
    @Published var showAlert = false

    @Published private(set) var shareURL: URL?
    @Published private(set) var config: LogConfiguration = .fallback
    @Published private(set) var entries: [OSLogEntryLog] = []
    @Published private(set) var isLoading = false

    // MARK: - Properties

    var filteredEntries: [OSLogEntryLog] {
        guard !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return entries }
        let query = search.lowercased()
        return entries.filter { entry in
            entry.composedMessage.lowercased().contains(query) ||
            entry.category.lowercased().contains(query) ||
            entry.subsystem.lowercased().contains(query)
        }
    }

    private let decoder: OTFYAMLDecoding
    private let logger = OTFLogger.logger()
    private var store: OSLogStore?

    // MARK: - Init

    init(decoder: OTFYAMLDecoding = OTFYAMLDecoderEngine()) {
        self.decoder = decoder
        let fallback = LogConfiguration.fallback
        self.startDate = Calendar.current.date(byAdding: .day, value: -fallback.defaultDaysBack, to: Date()) ?? Date().addingTimeInterval(-86400)
        self.endDate = Date()
        loadConfig()
        configureStore()
        refresh()
    }

    // MARK: - Methods

    func loadConfig() {
        do {
            config = try decoder.decode(FileConstants.fileName, as: LogConfiguration.self)
        } catch {
            logger.error("LogConfiguration.yml decode failed: \(error.localizedDescription)")
            config = .fallback
        }
    }

    func configureStore() {
        do {
            store = try OSLogStore(scope: .currentProcessIdentifier)
        } catch {
            logger.error("OSLogStore init failed: \(error.localizedDescription)")
            showAlert(with: error)
        }
    }

    func refresh() {
        guard let store else { return }
        isLoading = true

        Task.detached(priority: .userInitiated) { [startDate, endDate, level] in
            do {
                let position = store.position(date: startDate)
                let predicate = NSPredicate(value: true)
                let items = try store.getEntries(at: position, matching: predicate)
                  .compactMap { $0 as? OSLogEntryLog }
                  .filter { entry in
                      guard entry.date >= startDate, entry.date <= endDate else { return false }
                      if level != .undefined, entry.level != level {
                          return false
                      }
                      return true
                  }
                await MainActor.run { [weak self] in
                    self?.entries = items
                    self?.isLoading = false
                    self?.shareURL = self?.exportURL()
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.entries = []
                    self?.isLoading = false
                    self?.showAlert(with: error)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func exportURL() -> URL? {
        do {
            let text = filteredEntries.map { entry in
                "[\(entry.date)] [\(entry.category)] [\(entry.level.rawValue)] [\(entry.subsystem)] \n\(entry.composedMessage)"
            }.joined(separator: "\n\n")
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("Diagnostics.log")
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            showAlert(with: error)
            return nil
        }
    }

    private func showAlert(with error: Error) {
        alertMessage = error.localizedDescription
        showAlert = true
    }
}
