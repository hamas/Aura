//
//  PictureInPictureController.swift
//  Aura
//
//  Wrapper for AVPictureInPictureController supporting seamless PiP mode.
//

import Foundation
import AVKit
import Combine

public final class PictureInPictureController: NSObject, ObservableObject, AVPictureInPictureControllerDelegate {
    @Published public var isPiPActive: Bool = false
    @Published public var isPiPSupported: Bool = AVPictureInPictureController.isPictureInPictureSupported()
    
    private var pipController: AVPictureInPictureController?
    
    public func setup(with playerLayer: AVPlayerLayer) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        
        pipController = AVPictureInPictureController(playerLayer: playerLayer)
        pipController?.delegate = self
    }
    
    public func togglePiP() {
        guard let controller = pipController else { return }
        if controller.isPictureInPictureActive {
            controller.stopPictureInPicture()
        } else {
            controller.startPictureInPicture()
        }
    }
    
    // MARK: - AVPictureInPictureControllerDelegate
    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isPiPActive = true
    }
    
    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isPiPActive = false
    }
}
