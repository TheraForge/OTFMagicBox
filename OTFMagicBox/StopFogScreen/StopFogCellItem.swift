//
//  StopFogCellItem.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 8/19/22.
//

import SwiftUI

struct StopFogCellItem: View {
    var item: CellItem
    var isEditing: Bool
    var deleteCellAction: ((CellItem) -> Void)?
    
    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .center) {
                if isEditing {
                    UIImage.loadImage(named:"minus.circle")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Colors.secondary)
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .padding(.trailing, 16)
                        .onTapGesture {
                            deleteCellAction?(item)
                        }
                }
                Text(item.title)
                    .medium(size: 24)
                Spacer()
                if !isEditing {
                    VStack(alignment: .center) {
                        UIImage.loadImage(named: item.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 32)
                    }.frame(width: 57)
                }
            }.padding([.leading,.trailing], isEditing ? 0 : 12)
                .offset(x: isEditing ? -16 : 0)
            Spacer()
            if !item.isLastCell {
                Divider()
                    .padding([.leading,.trailing], 8)
            }
        }
    }
}

struct StopFogCellItem_Previews: PreviewProvider {
    static var previews: some View {
        StopFogCellItem(item: CellItem(title: "Some title", releaseAction: .metronome), isEditing: false)
    }
}
