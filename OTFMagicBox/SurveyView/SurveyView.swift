//
//  SurveyView.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 8/24/22.
//

import SwiftUI
import OTFResearchKit
import OTFCareKit

struct SurveyView: View {
    @ObservedObject var viewModel: SurveyViewModel
    @State var shouldPresentSurvey = false
    
    var body: some View {
        VStack(spacing: 0) {
            MainHeaderView(title: "Daily Checkup")
                .frame(height: 90)
            if $viewModel.allSurveysTaken.wrappedValue {
                VStack(spacing: 20) {
                    UIImage.loadImage(named: "checkmark.circle.fill")
                        .renderingMode(.template)
                        .resizable()
                        .foregroundColor(Colors.primary)
                        .scaledToFit()
                        .frame(width: UIScreen.main.bounds.width/2)
                    Text("We are All done for Today!").medium(size: 27)
                }
                .padding([.top, .bottom], 30)
                .background((UITableView.appearance().backgroundColor ?? .white).suiColor)
            }
            List(viewModel.cards) { card in
                Section(header: EmptyView(), footer: EmptyView()) {
                    SurveyCardCell(card: card, action: {
                        $viewModel.cardToPresent.wrappedValue = card
                        shouldPresentSurvey = true
                    })
                        .buttonStyle(.plain)
                }
            }.listStyle(.insetGrouped)
            Spacer()
        }
        .onAppear(perform: {
            viewModel.checkForStoredSurveys()
        })
        .fullScreenCover(isPresented: $shouldPresentSurvey, onDismiss: {
            viewModel.cardToPresent = nil
            shouldPresentSurvey = false
        }) {
            viewModel.getTaskViewController(for: viewModel.cardToPresent!.surveyTask).navigationBarHidden(true)
        }
        Spacer()
    }
}

struct SurveyView_Previews: PreviewProvider {
    static var previews: some View {
        SurveyView(viewModel: SurveyViewModel())
    }
}
