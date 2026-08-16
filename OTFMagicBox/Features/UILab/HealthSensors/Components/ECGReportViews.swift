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

import CoreTransferable
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct ECGReportInlineView: View {
    private enum FileConstants {
        static let actionVerticalPadding: CGFloat = 4
        static let previewHeight: CGFloat = 220
        static let spacing: CGFloat = 12
    }

    let report: ECGReport
    @State private var showsFullReport = false

    var body: some View {
        VStack(alignment: .leading, spacing: FileConstants.spacing) {
            HealthSensorSectionTitle(
                title: ECGReportCopy.title,
                systemImage: "doc.richtext"
            )

            ECGReportPreviewView(data: report.pdfData)
                .frame(height: FileConstants.previewHeight)
                .background(Color(.secondarySystemBackground))
                .clipShape(.rect(cornerRadius: HealthSensorVisualStyle.cardCornerRadius))
                .overlay {
                    RoundedRectangle(
                        cornerRadius: HealthSensorVisualStyle.cardCornerRadius,
                        style: .continuous
                    )
                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                }
                .accessibilityLabel(ECGReportCopy.previewAccessibilityLabel)

            Divider()

            Button {
                showsFullReport = true
            } label: {
                Text(ECGReportCopy.openFullReport)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
            }
            .font(.body)
            .foregroundStyle(Color.accentColor)
            .buttonStyle(.plain)
            .padding(.vertical, FileConstants.actionVerticalPadding)
            .accessibilityHint(ECGReportCopy.openAccessibilityHint)

            Divider()

            Text(ECGReportCopy.provenance)
                .font(.footnote)
                .foregroundStyle(Color.secondary)
        }
        .sheet(isPresented: $showsFullReport) {
            ECGReportDetailView(report: report)
        }
    }
}

private struct ECGReportPreviewView: View {
    private let image: Image?

    init(data: Data) {
        guard
            let page = PDFDocument(data: data)?.page(at: 0)
        else {
            image = nil
            return
        }

        let pageSize = page.bounds(for: .mediaBox).size
        image = Image(uiImage: page.thumbnail(of: pageSize, for: .mediaBox))
    }

    var body: some View {
        Group {
            if let image {
                image
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "doc.richtext")
                    .font(.largeTitle)
                    .foregroundStyle(Color.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ECGReportDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let report: ECGReport

    var body: some View {
        NavigationStack {
            ECGReportPDFView(data: report.pdfData)
                .background(Color(.systemBackground))
                .navigationTitle(ECGReportCopy.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(ECGReportCopy.done) {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        ShareLink(
                            item: ECGReportTransfer(data: report.pdfData),
                            preview: SharePreview(ECGReportCopy.title)
                        ) {
                            Label(ECGReportCopy.shareReport, systemImage: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
}

private struct ECGReportTransfer: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { report in
            report.data
        }
    }
}

private struct ECGReportPDFView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.displaysPageBreaks = true
        view.pageShadowsEnabled = false
        view.backgroundColor = .secondarySystemBackground
        view.document = PDFDocument(data: data)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        guard view.document?.dataRepresentation() != data else { return }
        view.document = PDFDocument(data: data)
    }
}
