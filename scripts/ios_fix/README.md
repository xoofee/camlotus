write shell script to


1 replace in ios/Pods/SDWebImage/SDWebImage/Core/UIImage+Metadata.m

return self.isHighDynamicRange to return NO

2 comment out in ios/Pods/SDWebImage/SDWebImage/Core/SDImageIOAnimatedCoder.m

decodingOptions[(__bridge NSString *)kCGImageSourceDecodeRequest] = (__bridge NSString *)kCGImage SourceDecodeToHDR;

decodingOptions[(__bridge NSString *)kCGImageSourceDecodeRequest] = (__bridge NSString *)kCGImage SourceDecodeToSDR;


3 refactor in /Users/xf/.pub-cache/hosted/pub.dev/record_darwin-1.2.2/ios/Classes/RecordConfig.swift

convert this

```
#if os(iOS)
struct IosConfig {
  let categoryOptions: [AVAudioSession.CategoryOptions]
  let manageAudioSession: Bool

  init(map: [String: Any]) {
    let comps = map["categoryOptions"] as? String
    let options: [AVAudioSession.CategoryOptions]? = comps?.split(separator: ",").compactMap { part in
        let trimmed = part.trimmingCharacters(in: .whitespaces)
        switch trimmed {
        case "mixWithOthers":
            return .mixWithOthers
        case "duckOthers":
            return .duckOthers
        case "allowBluetooth":
            return .allowBluetooth
        case "defaultToSpeaker":
            return .defaultToSpeaker
        case "interruptSpokenAudioAndMixWithOthers":
            return .interruptSpokenAudioAndMixWithOthers
        case "allowBluetoothA2DP":
            return .allowBluetoothA2DP
        case "allowAirPlay":
            return .allowAirPlay
        case "overrideMutedMicrophoneInterruption":
            if #available(iOS 14.5, *) {
                return .overrideMutedMicrophoneInterruption
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    self.categoryOptions = options ?? []
    self.manageAudioSession = map["manageAudioSession"] as? Bool ?? true
  }
}
#else
struct IosConfig {
  init(map: [String: Any]) {}
}
```

to

```
#if os(iOS)
struct IosConfig {
  let categoryOptions: [AVAudioSession.CategoryOptions]
  let manageAudioSession: Bool
  init(map: [String: Any]) {
    let comps = map["categoryOptions"] as? String
    let options: [AVAudioSession.CategoryOptions]? = comps?.split(separator: ",").compactMap { part in
        let trimmed = part.trimmingCharacters(in: .whitespaces)
        switch trimmed {
        case "mixWithOthers":
            return .mixWithOthers
        case "duckOthers":
            return .duckOthers
        case "allowBluetooth":
            return .allowBluetooth
        case "defaultToSpeaker":
            return .defaultToSpeaker
        case "interruptSpokenAudioAndMixWithOthers":
            return .interruptSpokenAudioAndMixWithOthers
        case "allowBluetoothA2DP":
            return .allowBluetoothA2DP
        case "allowAirPlay":
            return .allowAirPlay
        case "overrideMutedMicrophoneInterruption":
            if #available(iOS 14.5, *) {
                return .overrideMutedMicrophoneInterruption
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    self.categoryOptions = options ?? []
    self.manageAudioSession = map["manageAudioSession"] as? Bool ?? true
  }
}
#else
struct IosConfig {
  init(map: [String: Any]) {}
}
```

if it's hard to use shell script to achieve the (3), you could use python or node.js script

remember to backup the original code first (may be copy with a .bak surfix)
