#if os(iOS)
import Flutter
import UIKit

public class AudioEnginePlugin: NSObject, FlutterPlugin {
  private var engine: Engine!

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "audio_engine", binaryMessenger: registrar.messenger())
    let instance = AudioEnginePlugin()
    instance.engine = Engine()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any]? else { return result(FlutterError(code:"args", message:"bad args", details:nil)) }

    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
      
    case "createTrack":
      guard let uri = args?["uri"] as? String else { return result(FlutterError(code:"arg", message:"uri required", details:nil)) }
      do { let id = try engine.createTrack(uri: uri); result(id) } catch { result(FlutterError(code:"create", message: error.localizedDescription, details:nil)) }

    case "disposeTrack":
      engine.disposeTrack(id: (args?["id"] as? NSNumber)?.intValue ?? 0); result(nil)

    case "setGain":
      engine.setGain(id: (args?["id"] as? NSNumber)?.intValue ?? 0, v: args?["v"] as? Double ?? 1.0); result(nil)

    case "setSpeed":
      engine.setSpeed(id: (args?["id"] as? NSNumber)?.intValue ?? 0, v: args?["v"] as? Double ?? 1.0); result(nil)

    case "setPitch":
      engine.setPitch(id: (args?["id"] as? NSNumber)?.intValue ?? 0, v: args?["v"] as? Double ?? 1.0); result(nil)

    case "setPan":
      engine.setPan(id: (args?["id"] as? NSNumber)?.intValue ?? 0, v: args?["v"] as? Double ?? 0.0); result(nil)

    case "start":
      engine.start(id: (args?["id"] as? NSNumber)?.intValue ?? 0, offsetMs: (args?["offsetMs"] as? NSNumber)?.intValue ?? 0); result(nil)

    case "stop":
      engine.stop(id: (args?["id"] as? NSNumber)?.intValue ?? 0); result(nil)

    case "startAll":
      let map = (args?["offsets"] as? [String: Any]) ?? [:]
      let parsed = Dictionary(uniqueKeysWithValues: map.compactMap { (k, v) in
        if let n = v as? NSNumber { return (Int(k)!, n.intValue) } else { return nil }
      })
      engine.startAll(offsetsMs: parsed); result(nil)

    case "stopAll":
      engine.stopAll(); result(nil)

    case "getParams":
      let id = (args?["id"] as? NSNumber)?.intValue ?? 0
      if let p = engine.getParams(id: id) {
        // return a map that's easy to read on the Dart side
        result([
          "gain": p.gain,
          "pan": p.pan,
          "rate": p.rate,
          "pitchFactor": p.pitchFactor,
        ])
      } else {
        result(FlutterError(code:"not_found", message:"track not found", details:nil))
      }
    
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
#endif