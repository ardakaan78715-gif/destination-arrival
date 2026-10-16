import AVFoundation

@MainActor
final class AlarmSoundPlayer: AlarmSounding {
    private let session = AVAudioSession.sharedInstance()
    private var player: AVAudioPlayer?
    private var sampleTimeout: Task<Void, Never>?

    var isVolumeLow: Bool {
        session.outputVolume < 0.25
    }

    func start() {
        cancelSampleTimeout()
        play()
    }

    func playSample(seconds: TimeInterval) {
        guard player == nil else { return }
        play()
        sampleTimeout = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(seconds))
            } catch {
                return
            }
            self?.stop()
        }
    }

    func stop() {
        cancelSampleTimeout()
        player?.stop()
        player = nil
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func play() {
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

    private func cancelSampleTimeout() {
        sampleTimeout?.cancel()
        sampleTimeout = nil
    }
}
