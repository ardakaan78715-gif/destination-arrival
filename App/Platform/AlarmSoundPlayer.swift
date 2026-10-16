import AVFoundation

@MainActor
final class AlarmSoundPlayer: AlarmSounding {
    private let session = AVAudioSession.sharedInstance()
    private var player: AVAudioPlayer?

    var isVolumeLow: Bool {
        session.outputVolume < 0.25
    }

    func start() {
        guard player == nil, let url = Bundle.main.url(forResource: "Alarm", withExtension: "caf") else { return }
        do {
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 1
            player.play()
            self.player = player
        } catch {
            stop()
        }
    }

    func stop() {
        player?.stop()
        player = nil
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }
}
