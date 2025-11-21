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
  private var looping = false
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

  // Schedule a single track at nil and calls player.play() immediately
  func start(offsetMs: Int) {
    looping = true
    player.stop()

    let sr = file.processingFormat.sampleRate
    let offsetFrames = AVAudioFramePosition((Double(offsetMs) / 1000.0) * sr)
    let clamped = max(0, min(offsetFrames, file.length))
    let remaining = AVAudioFrameCount(max(0, file.length - clamped))
    let fullCount = AVAudioFrameCount(file.length)
    guard fullCount > 0 else { return }

    if remaining > 0 {
      // Lead-in now: offset → end
      player.scheduleSegment(
        file,
        startingFrame: clamped,
        frameCount: remaining,
        at: nil,
        completionHandler: nil
      )
    } else {
      // Start from the top now
      player.scheduleSegment(
        file,
        startingFrame: 0,
        frameCount: fullCount,
        at: nil,
        completionHandler: nil
      )
    }

    queueFullLoop()
    let targetGain = gain
    mixer.outputVolume = 0.0
    player.play()
    fade(to: targetGain, duration: 1.0)
  }

  // Stops whatever is playing, mix or single
  func stop() {
    looping = false
    fade(to: 0.0, duration: 1.0, completion: nil)

    /*
    let currentGain = mixer.outputVolume
    fade(to: 0.0, duration: 1.0) { [weak self] in
      guard let self = self else { return }
      self.player.stop()
      self.mixer.outputVolume = currentGain
    }
    */
  }

  func dispose() {
    stop()
    // Nodes stay attached; engine owns them.
  }

  // MARK: - Looping internals

  /// Always keep one full-file segment queued; when it finishes, enqueue another, used by mix and single
  private func queueFullLoop() {
    guard looping else { return }
    let fullCount = AVAudioFrameCount(file.length)
    guard fullCount > 0 else { return }

    // Append directly after whatever is already queued.
    player.scheduleSegment(
      file,
      startingFrame: 0,
      frameCount: fullCount,
      at: nil
    ) { [weak self] in
      self?.queueFullLoop()
    }
  }

  // Fade logic to fade in and out when playing sounds.
  private func fade(to target: Float,
                    duration: TimeInterval = 0.02,
                    completion: (() -> Void)? = nil) {
    print(">>> FADE CALLED: target=\(target), duration=\(duration)")
    let steps = 20
    let stepDuration = duration / Double(steps)
    let start = mixer.outputVolume
    let delta = target - start

    guard steps > 0, duration > 0 else {
      mixer.outputVolume = target
      completion?()
      return
    }

    var i = 0
    func step() {
      i += 1
      let t = Double(i) / Double(steps)
      mixer.outputVolume = start + delta * Float(t)
      if i >= steps {
        completion?()
      } else {
        DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration, execute: step)
      }
    }

    DispatchQueue.main.async(execute: step)
  }
}