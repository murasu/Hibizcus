# Hibizcus

Font proofing and debugging tools.
Written by: Muthu Nedumaran

Hibizcus is a collection of tools written to proof and debug in-house developed fonts for South Asian and South East Asian scripts. Originally written in Objective-C these tools were used to visually present the layout of text shaped by CoreText using data in AAT tables added to the fonts. This project includes some of the most frequently used tools, rewritten in Swift and presented in SwiftUI. 

The tools in this project have all been updated to support OpenType tables, in addition to AAT. Shaping can be done via CoreText and Harfbuzz for comparison.

You can get the released version from the Mac App Store: https://apps.apple.com/us/app/hibizcus/id1567526979

## Pre-requisits

1. A machine running macOS 11.0 (Big Sur) or later
2. XCode 12.0 or later

## Third-party libraries

1. Harfbuzz : https://github.com/harfbuzz/harfbuzz
2. Otfcc : https://github.com/caryll/otfcc
3. BinarySwift : https://cocoapods.org/pods/BinarySwift

Pre-built libraries for all the above are included in the repo

## Steps to build

1. Clone the repo
2. Open the project in Xcode
3. Create an assets file
    - The original Hibizcus icon/logo is copyrighted and thus is not included in the repo. 
    - Create Assets.xcassets in Hibizcus/Hibizcus and add an applogo.
4. Create an icon file for documents (.icns) and set it as the document icon in info.plist
5. Build and run

## Wordlists and cluster data

1. Text files containing a list of words for each supported language can be found in Hibizcus/Shared/Resources. The filenames will be in the format script_language.txt (eg: devanagari_hindi.txt)
2. Cluster data can be found in the same directory. The names of these JSON files will be in the format cluster_script.json (eg: cluster_tamil.json). The format is described in the Readme file in that directory. 

