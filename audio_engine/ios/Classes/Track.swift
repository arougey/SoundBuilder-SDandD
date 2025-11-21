import AVFoundation
#if canImport(AVFAudio)
import AVFAudio
#endif

final class Track {
  private let engine: AVAudioEngine
  private let player = AVAudioPlayerNode()
  private let varispeed = AVAudioUnitVarispeed()     // NEW: better for rate changes
  private let timePitch = AVAudioUnitTimePitch()     // keep just for pitch shifts
  let mixer = AVAudioMixerNode()             // per-track gain/pan
  private let file: AVAudioFile

  var gain: Float = 1.0 { didSet { mixer.outputVolume = gain } }
  var pan: Float = 0.0  { didSet { mixer.pan = pan } } // -1..+1

  var pitchFactor: Float = 1.0 { didSet { applyPitchAndRate() } } // factor (1.0 = no change)
  var rate: Float = 1.0        { didSet { applyPitchAndRate() } } // 0.25..4.0

  init(engine: AVAudioEngine, uri: String) throws {
    self.engine = engine
    guard let url = URL(string: uri), url.isFileURL else {
      throw NSError(domain: "Track", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad file uri: \(uri)"])
    }
    self.file = try AVAudioFile(forReading: url)

    print("[track] fileFormat:", file.processingFormat)
    print("[track] mixer format (bus0):", mixer.outputFormat(forBus: 0))

    engine.attach(player)
    engine.attach(varispeed)
    engine.attach(timePitch)
    engine.attach(mixer)

    let fileFormat = file.processingFormat
    // Promote to stereo at the mixer so 'pan' is effective and avoids odd mono panning.
    let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: fileFormat.sampleRate, channels: 2)!

    // player -> varispeed (rate) -> timePitch (pitch) -> mixer (gain/pan) -> main
    engine.connect(player,    to: varispeed, format: fileFormat)
    engine.connect(varispeed, to: timePitch, format: fileFormat)
    engine.connect(timePitch, to: mixer,     format: stereoFormat)

    mixer.outputVolume = gain
    mixer.pan = pan
    applyPitchAndRate()
  }

  private func applyPitchAndRate() {
    // Bypass both DSP units when neutral to avoid needless quality loss.
    let neutralRate = abs(rate - 1.0) < 0.0001
    let neutralPitch = abs(pitchFactor - 1.0) < 0.0001

    varispeed.rate = max(0.25, min(rate, 4.0))                 // 0.25..4
    timePitch.pitch = Float(12.0 * log2(Double(max(pitchFactor, 0.001))) * 100.0)

    varispeed.bypass = neutralRate
    timePitch.bypass = neutralPitch
  }

  func schedule(offsetMs: Int, at when: AVAudioTime) {
    let sr = file.processingFormat.sampleRate
    let offsetFrames = AVAudioFramePosition((Double(offsetMs) / 1000.0) * sr)
    let clamped = max(0, min(offsetFrames, file.length))
    let remaining = AVAudioFrameCount(file.length - clamped)
    player.stop()
    file.framePosition = clamped
    player.scheduleSegment(file, startingFrame: clamped, frameCount: remaining, at: when, completionHandler: nil)
  }

  func play(at when: AVAudioTime) {
    if !player.isPlaying {
      player.play(at: when)
    }
  }

  func start(offsetMs: Int) {
    // Immediate start: schedule now and call play() without explicit time
    let sr = file.processingFormat.sampleRate
    let offsetFrames = AVAudioFramePosition((Double(offsetMs) / 1000.0) * sr)
    let clamped = max(0, min(offsetFrames, file.length))
    let remaining = AVAudioFrameCount(file.length - clamped)
    player.stop()
    file.framePosition = clamped
    player.scheduleSegment(file, startingFrame: clamped, frameCount: remaining, at: nil, completionHandler: nil)
    player.play()
  }

  func stop() {
    player.stop()
  }

  func dispose() {
    stop()
    // Nodes stay attached; engine owns them. No explicit detach required unless you want to.
  }
}