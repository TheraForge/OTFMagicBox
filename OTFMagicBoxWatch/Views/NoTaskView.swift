//
//  NoTaskView.swift
//  OTFMagicBoxWatch
//
//  Created by Waqas Khadim on 25/07/2024.
//

import SwiftUI

struct NoTaskView: View {
    
    let formatter = DateFormatter()
    var date: String
    
    init() {
        formatter.dateFormat = "d MMM YYYY"
        date = formatter.string(from: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(date)
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
    NoTaskView()
}
