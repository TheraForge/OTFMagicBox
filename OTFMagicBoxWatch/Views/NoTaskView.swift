//
//  NoTaskView.swift
//  OTFMagicBoxWatch
//
//  Created by Waqas Khadim on 25/07/2024.
//

import SwiftUI

struct NoTaskView: View {
    
    var displayDate: String
    
    init(displayDate: String) {
        self.displayDate = displayDate
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(displayDate)
                .fontWeight(.bold)
                .padding(.bottom, 5)
            VStack(alignment: .leading) {
                Text(Constants.notask)
                    .fontWeight(.bold)
                Text(Constants.notaskToday)
                    .font(.system(size: 12))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.4))
            .cornerRadius(6)
            .shadow(color: .gray, radius: 0.3, x: 0, y: 0.3)
        }
    }
}

#Preview {
    let formatter = DateFormatter()
    let displayDate = formatter.string(from: Date())
    NoTaskView(displayDate: displayDate)
}
