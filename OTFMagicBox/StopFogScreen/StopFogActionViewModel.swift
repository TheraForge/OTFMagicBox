//
//  StopFogActionViewModel.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 8/27/22.
//

import Foundation
import AVFoundation
import SwiftUI

class StopFogActionViewModel: ObservableObject {
    @Published var action: CellItem
    @Published var image: Image = Image("StopFogAnimation")

    var playingItemIndex = 0
    var animatingImageIndex = 0
    var actionList: [CellItem]
    var player: AVAudioPlayer?
    var timer: Timer?
    
    init(actionList: [CellItem]) {
        self.actionList = actionList
        action = actionList[0]
        startAction()
    }
    
    func startAction() {
        action = actionList[playingItemIndex]
        let imageCount = action.animatedImages.count
        if action.audioFileName != "" {
            playAudio(at: action.audioFileName)
        }
        if imageCount > 0 {
            image = action.animatedImages[animatingImageIndex]
            timer = Timer.scheduledTimer(timeInterval: TimeInterval(Double(1)/Double(imageCount)), target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        } else {
            image = UIImage.loadImage(named: action.image)
        }
    }
    @objc
    func timerFired() {
        animatingImageIndex += 1
        if animatingImageIndex > action.animatedImages.count-1 {
            animatingImageIndex = 0
        }
        image = action.animatedImages[animatingImageIndex]
    }
    
    func stopActions() {
        player?.stop()
        timer?.invalidate()
        animatingImageIndex = 0
    }
    func nextAction() {
        stopActions()
        if playingItemIndex == actionList.count-1 {
            playingItemIndex = 0
        } else {
            playingItemIndex += 1
        }
        startAction()
        print("PLAYING NEXT ACTION")
    }
    
    func playAudio(at name: String) {
        guard let path = Bundle.main.path(forResource: name, ofType:"mp3") else {
            return }
        let url = URL(fileURLWithPath: path)
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
}
