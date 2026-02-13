/*
This is a script to fix the Android Java version issue. It solves this problem:

Execution failed for task ':flutter_plugin_android_lifecycle:compileReleaseJavaWithJavac'.> Could not resolve all files for configuration ':flutter_plugin_android_lifecycle:releaseCompileClasspath'.

If you want to use it, you need to change it to the java version you want to use.

for each package of 
    - shared_preferences_android
    - path_provider_android

search for all <package-name>-xxxx
in each folder, search for android/build.gradle, then do the following:


1 substitude JavaVersion.VERSION_11 with JavaVersion.VERSION_1_8

2 find the line that contains kotlinOptions, and jvmTarget = xxx

    kotlinOptions {
        jvmTarget = xxx
    } 

  replace xxx with JavaVersion.VERSION_1_8

Usage:
npx ts-node android_fix.ts
npx ts-node D:\work\camlotus\codes\camlotus\IndoorEasy\app\camlotus\scripts\android_fix\android_fix.ts
*/

// @ts-nocheck

import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';


// tested on windows
const PUB_CACHE_PATH = path.join(os.homedir(), 'AppData', 'Local', 'Pub', 'Cache', 'hosted', 'pub.dev');

// Define the packages to search for
const TARGET_PACKAGES = [
  'shared_preferences_android',
  'path_provider_android',
  'record_android',
  'flutter_plugin_android_lifecycle',
  'url_launcher_android',
  'gal',
  'camera_android_camerax',
];

async function findTargetPackages(): Promise<string[]> {
  const packages: string[] = [];
  
  try {
    const pubCacheDir = fs.readdirSync(PUB_CACHE_PATH);
    
    for (const item of pubCacheDir) {
      // Check if the item starts with any of our target package names
      for (const packageName of TARGET_PACKAGES) {
        if (item.startsWith(`${packageName}-`)) {
          packages.push(path.join(PUB_CACHE_PATH, item));
          break; // Avoid adding the same package twice
        }
      }
    }
  } catch (error) {
    console.error('Error reading pub cache directory:', error);
  }
  
  return packages;
}

async function modifyBuildGradle(packagePath: string): Promise<boolean> {
  const buildGradlePath = path.join(packagePath, 'android', 'build.gradle');
  
  try {
    if (!fs.existsSync(buildGradlePath)) {
      console.log(`Build.gradle not found in ${packagePath}`);
      return false;
    }
    
    let content = fs.readFileSync(buildGradlePath, 'utf8');
    const originalContent = content;
    
    // Replace JavaVersion.VERSION_11 with JavaVersion.VERSION_1_8
    content = content.replace(/JavaVersion\.VERSION_11/g, 'JavaVersion.VERSION_1_8');
    content = content.replace(/JavaVersion\.VERSION_17/g, 'JavaVersion.VERSION_1_8');
    
    // Find and replace kotlinOptions jvmTarget
    // This regex matches kotlinOptions block and captures the jvmTarget value
    const kotlinOptionsRegex = /kotlinOptions\s*\{\s*jvmTarget\s*=\s*([^}]+)\s*\}/;
    const kotlinOptionsMatch = content.match(kotlinOptionsRegex);
    
    if (kotlinOptionsMatch) {
      // Replace the jvmTarget value with JavaVersion.VERSION_1_8
      content = content.replace(kotlinOptionsRegex, (match, jvmTargetValue) => {
        return match.replace(jvmTargetValue.trim(), 'JavaVersion.VERSION_1_8');
      });
      console.log(`Found and updated kotlinOptions in: ${buildGradlePath}`);
    }
    
    if (content !== originalContent) {
      fs.writeFileSync(buildGradlePath, content, 'utf8');
      console.log(`Modified: ${buildGradlePath}`);
      return true;
    } else {
      console.log(`No changes needed: ${buildGradlePath}`);
      return false;
    }
  } catch (error) {
    console.error(`Error modifying ${buildGradlePath}:`, error);
    return false;
  }
}

async function main() {
  console.log('Starting Android Java version fix...');
  console.log(`Searching for packages: ${TARGET_PACKAGES.join(', ')}`);
  console.log(`Searching in: ${PUB_CACHE_PATH}`);
  
  const packages = await findTargetPackages();
  
  if (packages.length === 0) {
    console.log(`No target packages found (${TARGET_PACKAGES.join(', ')}).`);
    return;
  }
  
  console.log(`Found ${packages.length} target packages:`);
  packages.forEach(pkg => console.log(`  - ${path.basename(pkg)}`));
  
  let modifiedCount = 0;
  
  for (const packagePath of packages) {
    const modified = await modifyBuildGradle(packagePath);
    if (modified) {
      modifiedCount++;
    }
  }
  
  console.log(`\nCompleted! Modified ${modifiedCount} build.gradle files.`);
}

// Run the script
main().catch(console.error);
