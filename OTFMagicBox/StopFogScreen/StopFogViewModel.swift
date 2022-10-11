//
//  StopFogViewModel.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 8/19/22.
//

import Foundation
import SwiftUI
import OTFCloudantStore

class StopFogViewModel: ObservableObject {
    @Published var items: [CellItem] = []
    
    init() {
        items = [CellItem(title: "Play Metronome", releaseAction: .metronome),
                 CellItem(title: "Play Recording", releaseAction: .recording),
                 CellItem(title: "Play Music", releaseAction: .music),
                 CellItem(title: "Change Direction", releaseAction: .changeDirection),
                 CellItem(title: "Shift Weight & Step", releaseAction: .shiftWeight),
                 CellItem(title: "Raise Knee & Step", releaseAction: .raiseKnee),
                 CellItem(title: "Move Body Part", releaseAction: .moveBodyPart),
                 CellItem(title: "Step Over Line", releaseAction: .stepOverLine),
                 CellItem(title: "Dance", releaseAction: .dance, isLastCell: true)]
    }
    
    func deleteCellAction(itemToDelete: CellItem) {
        guard items.count > 1 else { return }
        items.removeAll { $0.id == itemToDelete.id }
        items[items.count-1].isLastCell = true
    }
    
    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        for i in 0..<items.count {
            items[i].isLastCell = i == items.count-1
        }
    }
}

struct CellItem: Codable & Identifiable & OTFCloudantRevision {
    var revId: String?
    
    var id = UUID()
    var title: String
    var releaseAction: ReleaseFoGAction
    var audioFileName: String { releaseAction.defaultAudioName }//todo: handle custom filenames
    var animatedImage: String { releaseAction.defaultAnimationName }
    var image: String { releaseAction.imageNameForAction }
    var isLastCell: Bool = false
//    var action: (()->Void)?
    
    var animatedImages: [Image] {
        
        var i = 0
        var images = [Image]()
        
        while let image = UIImage(named: "\(animatedImage)_\(i)") {
            images.append(Image(uiImage: image))
            i += 1
        }
        return images
    }
}

enum ReleaseFoGAction: Int, Codable {
    case metronome = 0
    case recording = 1
    case music
    case changeDirection
    case shiftWeight
    case raiseKnee
    case moveBodyPart
    case stepOverLine
    case dance
    
    var imageNameForAction: String {
        switch self {
        case .metronome:
            return "metronome"
        case .recording:
            return "music.mic"
        case .music:
            return "music.note"
        case .changeDirection:
            return "arrow.up.right.diamond"
        case .shiftWeight:
            return "square.and.line.vertical.and.square.fill"
        case .raiseKnee:
            return "shift.fill"
        case .moveBodyPart:
            return "tortoise.fill"
        case .stepOverLine:
            return "arrow.right.to.line"
        case .dance:
            return "arrow.clockwise.circle"
        }
    }
    
    var defaultAnimationName: String {
        switch self {
        case .metronome:
            return "metronome"
        default:
            return ""
        }
    }
    
    var defaultAudioName: String {
        switch self {
        case .metronome:
            return "metronome120"
        case .music:
            return "CalmnessSound"
        case .recording:
            return "SoothingVoice"
        default:
            return ""
        }
    }
}
