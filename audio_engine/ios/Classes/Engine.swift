import AVFoundation
import AudioToolbox

final class Engine {
  private let engine = AVAudioEngine()
  private let submix = AVAudioMixerNode()
  private var limiter: AVAudioUnit? = nil

  private var tracks: [Int: Track] = [:]
  private var nextId = 1

  init() {
    #if os(iOS)
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
      try session.setPreferredSampleRate(44100)
      try session.setActive(true)
    } catch {
      NSLog("[audio_engine][Engine] AVAudioSession error: \(error.localizedDescription)")
    }
    #endif

    // Attach nodes
    engine.attach(submix)
    let desc = AudioComponentDescription(
      componentType: kAudioUnitType_Effect,
      componentSubType: kAudioUnitSubType_DynamicsProcessor,
      componentManufacturer: kAudioUnitManufacturer_Apple,
      componentFlags: 0,
      componentFlagsMask: 0
    )

    let dyn = AVAudioUnitEffect(audioComponentDescription: desc) // no 'try'
    limiter = dyn
    engine.attach(dyn)

    // Configure via parameterTree (optional if available)
    if let tree = dyn.auAudioUnit.parameterTree {
      // Dynamics Processor parameter addresses:
      // 0: Threshold (dB), 1: Headroom (dB), 2: Attack (s), 3: Release (s), 4: MasterGain (dB)
      tree.parameter(withAddress: 0)?.value = -6.0    // threshold
      tree.parameter(withAddress: 2)?.value = 0.001   // attack
      tree.parameter(withAddress: 3)?.value = 0.05    // release
      tree.parameter(withAddress: 4)?.value = 0.0     // master gain
    }

    // --- Wire graph: submix -> (limiter?) -> main ---
    let outFmt = engine.outputNode.outputFormat(forBus: 0)
    let stereo = AVAudioFormat(standardFormatWithSampleRate: outFmt.sampleRate, channels: 2)!
    if let lim = limiter {
      engine.connect(submix, to: lim, format: stereo)
      engine.connect(lim, to: engine.mainMixerNode, format: stereo)
    } else {
      engine.connect(submix, to: engine.mainMixerNode, format: stereo)
    }

    engine.mainMixerNode.outputVolume = 0.7

    // Peak meter
    submix.installTap(onBus: 0, bufferSize: 2048, format: nil) { [weak self] buffer, _ in
      self?.logPeak(from: buffer)
    }

    print("[engine] output format:", engine.outputNode.outputFormat(forBus: 0))
  }

  private func logPeak(from buffer: AVAudioPCMBuffer) {
    guard let data = buffer.floatChannelData else { return }
    var peak: Float = 0
    let ch = Int(buffer.format.channelCount)
    let frames = Int(buffer.frameLength)
    for c in 0..<ch {
      let ptr = data[c]
      for i in 0..<frames {
        let v = abs(ptr[i])
        if v > peak { peak = v }
      }
    }
    if peak > 0.98 {
      NSLog("[audio_engine] WARNING near clipping, peak=%.3f", peak)
    } else {
      // Uncomment to see continuous levels
      // NSLog("[audio_engine] peak=%.3f", peak)
    }
  }

  deinit {
    submix.removeTap(onBus: 0)
  }

  // When creating a track, connect its per-track mixer INTO submix (not main):
  @discardableResult
  func createTrack(uri: String) throws -> Int {
    let id = nextId; nextId += 1
    let t = try Track(engine: engine, uri: uri)

    // IMPORTANT: connect the track’s mixer to the Engine’s submix (stereo)
    let mixerFormat = t.mixer.outputFormat(forBus: 0) // will be stereo per the Track
    engine.connect(t.mixer, to: submix, format: mixerFormat)

    tracks[id] = t
    startEngineIfNeeded()
    return id
  }

  private func startEngineIfNeeded() {
    if !engine.isRunning {
      do { try engine.start() }
      catch { NSLog("[audio_engine][Engine] engine.start() failed: \(error.localizedDescription)") }
    }
  }

  func disposeTrack(id: Int) {
    tracks[id]?.dispose()
    tracks.removeValue(forKey: id)
  }

  func setGain(id: Int, v: Double)  { tracks[id]?.gain        = Float(v) }
  func setPan(id: Int, v: Double)   { tracks[id]?.pan         = Float(v) }
  func setSpeed(id: Int, v: Double) { tracks[id]?.rate        = Float(v) }
  func setPitch(id: Int, v: Double) { tracks[id]?.pitchFactor = Float(v) }

  func start(id: Int, offsetMs: Int) {
    startEngineIfNeeded()
    tracks[id]?.start(offsetMs: offsetMs)
  }

  func stop(id: Int) { tracks[id]?.stop() }

  func startAll(offsetsMs: [Int: Int]) {
    startEngineIfNeeded()
    for (id, off) in offsetsMs {
      tracks[id]?.start(offsetMs: off)
    }
  }

  func stopAll() { tracks.values.forEach { $0.stop() } }

  // Tiny helper so the compiler doesn’t insist on AVFAudio at parse time
  @inline(__always) private func _isAVFAudioAvailable() -> Bool {
    #if canImport(AVFAudio)
      return true
    #else
      return false
    #endif
  }

  // Return current params for a given track id (or nil if missing)
  func getParams(id: Int) -> (gain: Float, pan: Float, rate: Float, pitchFactor: Float)? {
    guard let t = tracks[id] else { return nil }
    return (t.gain, t.pan, t.rate, t.pitchFactor)
  }
}