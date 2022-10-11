//
//  SurveyCardCell.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 8/26/22.
//

import SwiftUI

struct SurveyCardCell: View {
    var card: SurveyCard
    var action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Text(card.title)
                .regular(size: 17)
                .padding([.leading, .trailing], 16)
            HStack {
                
            }.frame(height: 1)
            .padding([.leading, .trailing], 16)
            .background(Color.gray)
            if !card.isAlreadyTaken {
                ZStack {
                    Rectangle().frame(height: 42)
                    .padding([.leading, .trailing], 16)
                    .background(Colors.primary)
                    .foregroundColor(Colors.primary)
                    .cornerRadius(8)
                    Text(card.buttonTitle)
                        .medium(size: 17)
                        .foregroundColor(.white)
                } .onTapGesture {
                    action?()
                }
            }
        }
        .cornerRadius(12)
        .padding([.top, .bottom], 16)
        .background(Color.white)
    }
}

struct SurveyCardCell_Previews: PreviewProvider {
    static var previews: some View {
        SurveyCardCell(card: SurveyCard(title: "some title", buttonTitle: "action", surveyTask: TaskListRow.customBooleanQuestion.representedTask))
    }
}
