/*
This is a script to fix iOS build issues related to:
1. SDWebImage HDR image handling
2. record_darwin audio session configuration

Usage:

npx ts-node .\scripts\ios_fix\ios_fix.ts

npx ts-node ios_fix.ts
npx ts-node D:\work\camlotus\codes\camlotus\IndoorEasy\app\camlotus\scripts\ios_fix\ios_fix.ts
*/

// @ts-nocheck

import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

// ES module equivalent of __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Cross-platform pub cache path
const PUB_CACHE_PATH = process.platform === 'win32' 
  ? path.join(os.homedir(), 'AppData', 'Local', 'Pub', 'Cache', 'hosted', 'pub.dev')
  : path.join(os.homedir(), '.pub-cache', 'hosted', 'pub.dev');

// Paths relative to project root
const PROJECT_ROOT = path.resolve(__dirname, '../..');

function backupFile(filePath: string): void {
  if (!fs.existsSync(filePath)) {
    console.log(`File not found: ${filePath}`);
    return;
  }
  
  const backupPath = `${filePath}.bak`;
  if (!fs.existsSync(backupPath)) {
    fs.copyFileSync(filePath, backupPath);
    console.log(`Backed up: ${filePath} -> ${backupPath}`);
  } else {
    console.log(`Backup already exists: ${backupPath}`);
  }
}

// Task 1: Replace return self.isHighDynamicRange with return NO
function fixUIImageMetadata(): void {
  const filePath = path.join(PROJECT_ROOT, 'ios', 'Pods', 'SDWebImage', 'SDWebImage', 'Core', 'UIImage+Metadata.m');
  
  if (!fs.existsSync(filePath)) {
    console.log(`File not found: ${filePath}`);
    return;
  }
  
  backupFile(filePath);
  
  let content = fs.readFileSync(filePath, 'utf8');
  const originalContent = content;
  
  // Replace return self.isHighDynamicRange with return NO
  // Match various possible formats: return self.isHighDynamicRange; or return [self isHighDynamicRange];
  content = content.replace(/return\s+(self\.isHighDynamicRange|\[self\s+isHighDynamicRange\]);?/g, 'return NO;');
  
  if (content !== originalContent) {
    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`✓ Fixed UIImage+Metadata.m`);
  } else {
    console.log(`No changes needed in UIImage+Metadata.m`);
  }
}

// Task 2: Comment out HDR/SDR decode options
function fixSDImageIOAnimatedCoder(): void {
  const filePath = path.join(PROJECT_ROOT, 'ios', 'Pods', 'SDWebImage', 'SDWebImage', 'Core', 'SDImageIOAnimatedCoder.m');
  
  if (!fs.existsSync(filePath)) {
    console.log(`File not found: ${filePath}`);
    return;
  }
  
  backupFile(filePath);
  
  let content = fs.readFileSync(filePath, 'utf8');
  const originalContent = content;
  
  // Comment out the HDR decode line
  // Note: The README shows "kCGImage SourceDecodeToHDR" with a space, but it's likely "kCGImageSourceDecodeToHDR"
  // We'll handle both cases
  content = content.replace(
    /(\s*)(decodingOptions\[\(__bridge NSString \*\)kCGImageSourceDecodeRequest\]\s*=\s*\(__bridge NSString \*\)kCGImageSourceDecodeToHDR;)/g,
    '$1// $2'
  );
  
  // Comment out the SDR decode line
  content = content.replace(
    /(\s*)(decodingOptions\[\(__bridge NSString \*\)kCGImageSourceDecodeRequest\]\s*=\s*\(__bridge NSString \*\)kCGImageSourceDecodeToSDR;)/g,
    '$1// $2'
  );
  
  // Also handle the case with space in the constant name (as shown in README)
  content = content.replace(
    /(\s*)(decodingOptions\[\(__bridge NSString \*\)kCGImageSourceDecodeRequest\]\s*=\s*\(__bridge NSString \*\)kCGImage\s+SourceDecodeToHDR;)/g,
    '$1// $2'
  );
  
  content = content.replace(
    /(\s*)(decodingOptions\[\(__bridge NSString \*\)kCGImageSourceDecodeRequest\]\s*=\s*\(__bridge NSString \*\)kCGImage\s+SourceDecodeToSDR;)/g,
    '$1// $2'
  );
  
  if (content !== originalContent) {
    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`✓ Fixed SDImageIOAnimatedCoder.m`);
  } else {
    console.log(`No changes needed in SDImageIOAnimatedCoder.m`);
  }
}

// Task 3: Refactor RecordConfig.swift
function fixRecordConfig(): void {
  // Find record_darwin package in pub cache
  let recordConfigPath: string | null = null;
  
  try {
    if (!fs.existsSync(PUB_CACHE_PATH)) {
      console.log(`Pub cache not found: ${PUB_CACHE_PATH}`);
      return;
    }
    
    const pubCacheDir = fs.readdirSync(PUB_CACHE_PATH);
    
    for (const item of pubCacheDir) {
      if (item.startsWith('record_darwin-')) {
        const candidatePath = path.join(PUB_CACHE_PATH, item, 'ios', 'Classes', 'RecordConfig.swift');
        if (fs.existsSync(candidatePath)) {
          recordConfigPath = candidatePath;
          break;
        }
      }
    }
  } catch (error) {
    console.error('Error reading pub cache directory:', error);
    return;
  }
  
  if (!recordConfigPath) {
    console.log(`RecordConfig.swift not found in pub cache`);
    return;
  }
  
  backupFile(recordConfigPath);
  
  let content = fs.readFileSync(recordConfigPath, 'utf8');
  const originalContent = content;
  
  // Find the IosConfig struct block (from #if os(iOS) to #endif)
  // We need to find the complete block including the #else part
  const iosConfigStart = content.indexOf('#if os(iOS)');
  
  if (iosConfigStart === -1) {
    console.log(`Could not find IosConfig struct in RecordConfig.swift`);
    return;
  }
  
  // Find the matching #endif - we need to count #if/#endif pairs
  let depth = 0;
  let iosConfigEnd = -1;
  let searchPos = iosConfigStart;
  
  while (searchPos < content.length) {
    const ifPos = content.indexOf('#if', searchPos);
    const endifPos = content.indexOf('#endif', searchPos);
    
    if (endifPos === -1) break;
    if (ifPos !== -1 && ifPos < endifPos) {
      depth++;
      searchPos = ifPos + 3;
    } else {
      depth--;
      if (depth === 0) {
        iosConfigEnd = endifPos + 6;
        break;
      }
      searchPos = endifPos + 6;
    }
  }
  
  if (iosConfigEnd === -1) {
    console.log(`Could not find matching #endif for IosConfig struct`);
    return;
  }
  
  // Extract the struct content to check if replacement is needed
  const structContent = content.substring(iosConfigStart, iosConfigEnd);
  
  // The target struct format from the README
  const newStruct = `#if os(iOS)
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
#endif`;
  
  // Normalize whitespace for comparison
  const normalize = (str: string) => str.replace(/\s+/g, ' ').trim();
  
  // Only replace if the content is different
  if (normalize(structContent) !== normalize(newStruct)) {
    content = content.substring(0, iosConfigStart) + newStruct + content.substring(iosConfigEnd);
    fs.writeFileSync(recordConfigPath, content, 'utf8');
    console.log(`✓ Fixed RecordConfig.swift`);
  } else {
    console.log(`RecordConfig.swift already matches target format`);
  }
}

async function main() {
  console.log('Starting iOS fixes...\n');
  
  console.log('Task 1: Fixing UIImage+Metadata.m...');
  fixUIImageMetadata();
  
  console.log('\nTask 2: Fixing SDImageIOAnimatedCoder.m...');
  fixSDImageIOAnimatedCoder();
  
  console.log('\nTask 3: Fixing RecordConfig.swift...');
  fixRecordConfig();
  
  console.log('\n✓ All iOS fixes completed!');
}

// Run the script
main().catch(console.error);

