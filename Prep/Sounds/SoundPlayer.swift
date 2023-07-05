import AVFoundation

class SoundPlayer {
    static let shared = SoundPlayer()
    
    enum Sound: String {
        case buttonTouchDown = "button_touchDown.wav"
        case calcbotClear = "calcbot_clear.wav"
        case calcbotDown = "calcbot_down.wav"
        case calcbotEquals = "calcbot_equals.wav"
        case calcbotUp = "calcbot_up.wav"
        case chord = "chord.wav"
        case clearDragPickup = "clear_DragPickup.wav"
        case clearDragPutdown = "clear_DragPutdown.wav"
        case clearSwoosh = "clear_swoosh.wav"
        case clearSwooshTap = "clear_swooshTap.wav"
        case clearTap = "clear_tap.wav"
        case click2 = "click2.wav"
        case click3 = "click3.wav"
        case click4 = "click4.wav"
        case click5 = "click5.wav"
        case emptyTrash = "emptyTrash.wav"
        case letterpressBip1 = "letterpress_bip1.wav"
        case letterpressBip2 = "letterpress_bip2.wav"
        case letterpressClick1 = "letterpress_click1.wav"
        case letterpressClick2 = "letterpress_click2.wav"
        case letterpressDelete = "letterpress_delete.wav"
        case letterpressSwoosh1 = "letterpress_swoosh1.wav"
        case letterpressSwoosh2 = "letterpress_swoosh2.wav"
        case octaveSlidePaper = "octave_slide-paper.wav"
        case octaveSlideScissors = "octave_slide-scissors.wav"
        case octaveTapSimple = "octave_tap-simple.wav"
        case octaveTapSmallest = "octave_tap-smallest.wav"
        case overlayOff2 = "overlayOff2.wav"
        case overlayOn2 = "overlayOn2.wav"
        case popClose = "popClose.wav"
        case popClose2 = "popClose2.wav"
        case popCloseLong = "popCloseLong.wav"
        case popOpen = "popOpen.wav"
        case popOpen2 = "popOpen2.wav"
        case tweetbotBubblePop = "tweetbot-bubble_pop.wav"
        case tweetbotButtonClick = "tweetbot-button_click.wav"
        case tweetbotCellSwoosh = "tweetbot-cell_swoosh.wav"
        case tweetbotSwipe = "tweetbot-swipe.wav"
        case tweetbotSwipeFail = "tweetbot-swipe_fail.wav"
        case tweetbotSwoosh = "tweetbot-swoosh.wav"
        case wellDone = "wellDone.wav"
        
        case chiptunesError = "chiptunes-error.wav"
        case chiptunesSuccess = "chiptunes-success.wav"
    }
    
    var scanSoundEffect: AVAudioPlayer? = nil

    static func play(_ sound: Sound) {
        shared.play(sound)
    }
    
    func play(_ sound: Sound) {
        guard let path = Bundle.main.path(forResource: sound.rawValue, ofType: nil) else {
            fatalError()
        }
        let url = URL(fileURLWithPath: path)

        do {
            try AVAudioSession.sharedInstance()
                .setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance()
                .setActive(true)
            scanSoundEffect = try AVAudioPlayer(contentsOf: url)
            scanSoundEffect?.play()
        } catch {
            fatalError()
        }
    }
}
