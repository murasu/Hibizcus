//
//  StringLayoutFontData.swift
//  LayoutView
//
//  Created by Muthu Nedumaran on 6/9/20.
//  Copyright © 2020 Murasu Systems Sdn bhd. All rights reserved.
//


import CoreText
import Combine
import SwiftUI

/*
struct StringLayoutFontMetics {
    
}

protocol StringLayoutFontShaper {
    func useFontFile(file:String)
    func getFontMetrics() -> StringLayoutFontMetics
    func shape(text:String) -> String
    func canTraceShaping() -> Bool
    func traceShaping(text:String) -> String
    func availableFeatures() -> Array<String>
} */

class StringLayoutShaper {
    
    var fontFilePath:String = ""
    // Font name & version
    var fontFileName:String = ""
    var displayName:String = ""
    var fontVersion:String = ""
    // Current text
    var currentText:String = ""
    
    // Shaper. CoreText is the default.
    // The other option is harfbuzz
    var shaper = "coretext"
    // CTFont
    var font:CTFont?
    
    // Scaled font-ascent metric
    var ascent:Float = 0
    // Scaled font-descent metric
    var descent:Float = 0
    // Leading
    var leading:Float = 0
    // UPEM
    var upem:Int32 = 0
    // Gyphs count
    var glyphCount:Int = 0
    // BBX
    var bbx:NSRect = NSRect(x: 0, y: 0, width: 0, height: 0)
    // Cap Height
    var capHeight:Float = 0
    // x height
    var xHeight:Float = 0
    // Underline
    var underline:Float = 0
    // Glyph to Unicode map
    var glyphToUnicode = [CGGlyph : UnicodeScalar]()
    
    // Harfbuzz shaper - only if this font is shaped with it
    let hbShaper = ExtShaperHb()
    
    init() {
        // TODO: Should I include a default font? Perhaps Noto Sans Devanagari?
        //setFont("/Users/muthu/Downloads/AnnaiMN-Regular.ttf")
    }
    
    func setShaper(newShaper:String) {
        self.shaper = newShaper
    }
    
    func setFont(filePath:String) {
        self.fontFilePath = filePath
        self.fontFileName = (filePath as NSString).lastPathComponent
        if loadFontDataFromFile() {
            print("Font data successfully obtained")
        }
        
        // TODO: Only do this if this layout is done by hb
        hbShaper.hbSetFontFilePath(fontFilePath)
    }
    
    func loadFontDataFromFile() -> Bool {
        // Get the data from harfbuzz if this is shaped by that engint
        let gotHb = getHBFontDataFromFile(atPath: fontFilePath)
        let gotCT = getCTFontDataFromFile(atPath: fontFilePath)
        return gotCT
    }
    
    // -------------------------------------------------------------
    // MARK: - Get Font Data
    // Font file data. Using CoreText just to get the data.
    // This does not do any layout
    // ------------------------------------------------------------
    func getHBFontDataFromFile(atPath: String) -> Bool {
        hbShaper.hbSetFontFilePath(atPath)
        let metrics = hbShaper.hbGetFontMetrics()
        print("Metrics from HB: \(metrics)")
        
        return true
    }
    
    func getCTFontDataFromFile(atPath: String) -> Bool {
        // Create the font descriptor with the font data
        var descriptor:CTFontDescriptor?
        
        //var languages:CFArray?
        var features:CFArray?
        //var loaded = false
        
        do {
            let fontData = try NSData(contentsOfFile: atPath) as CFData
            descriptor = CTFontManagerCreateFontDescriptorFromData(fontData)
            font = CTFontCreateWithFontDescriptor(descriptor!, 192.0, nil)
            //languages = CTFontCopySupportedLanguages(font!)
            features = CTFontCopyFeatures(font!)
            
            // Font name & version
            displayName = CTFontCopyDisplayName(font!) as String
            fontVersion = CTFontCopyName(font!, kCTFontVersionNameKey)! as String
            
            // Matrix
            
            // Scaled font-ascent metric
            ascent =  Float(CTFontGetAscent(font!))
            // Scaled font-descent metric
            descent = Float(CTFontGetDescent(font!))
            // Leading
            leading = Float(CTFontGetLeading(font!))
            // UPEM
            upem = Int32(CTFontGetUnitsPerEm(font!))
            // Gyphs count
            glyphCount = CTFontGetGlyphCount(font!)
            // BBX
            bbx = CTFontGetBoundingBox(font!) as NSRect
            // Cap Height
            capHeight = Float(CTFontGetCapHeight(font!))
            // x height
            xHeight = Float(CTFontGetXHeight(font!))
            // Underline
            underline = Float(CTFontGetUnderlinePosition(font!))
            
            // Get the glyph->unicode map
            glyphToUnicode = createGlyphToUnicodeMap(ctFont: font!)
            
            // For Later use
            /*
            let tableData = CTFontCopyTable(font!, CTFontTableTag(kCTFontTableAnkr), CTFontTableOptions(rawValue: 0))
            print("Ankr table obtained")
            let ankrTable = HbcAnkr(data: tableData! as Data)
            print("\(ankrTable.ankrDict)")
            */
        }
        catch {
            print("Error reading font: Can't load font descriptor from file at \(atPath)")
            return false
        }
        
        if features == nil {
        //    return (loaded:loaded, descriptor:descriptor!, font:font!, languages:languages!, features:nil, fontName:fontName!)
            print("features is nil")
        } else {
            print("features is NOT nil")
        }
        
        return true
    }
    
    func getStringLayoutViewData(forText:String) -> StringLayoutViewData? {
        // TODO: Choose either CoreText or Harfbuzz
        getStringLayoutViewDataWithHarfbuzz(forText: forText)
        
        return getStringLayoutViewDataWithCoreText(forText: forText)
    }
    
    // -----------------------------------------------------------------
    // MARK: - CoreText layout functions
    // Use CoreText to get the layout data for given string
    // -----------------------------------------------------------------
    
    func getStringLayoutViewDataWithCoreText(forText:String) -> StringLayoutViewData? {
        if font == nil {
            print("Font not loaded. Load the font first!")
            return nil
        }
        currentText = forText
        
        // Hardcode the color array
        let colorAlpha:CGFloat = 0.75
        var colorArray = [CGColor]()
        colorArray.append(NSColor.systemRed.withAlphaComponent(colorAlpha).cgColor)
        colorArray.append(NSColor.systemBlue.withAlphaComponent(colorAlpha).cgColor)
        colorArray.append(NSColor.systemBrown.withAlphaComponent(colorAlpha).cgColor)
        colorArray.append(NSColor.systemGreen.withAlphaComponent(colorAlpha).cgColor)
        colorArray.append(NSColor.systemOrange.withAlphaComponent(colorAlpha).cgColor)
        colorArray.append(NSColor.systemPink.withAlphaComponent(colorAlpha).cgColor)
        colorArray.append(NSColor.systemPurple.withAlphaComponent(colorAlpha).cgColor)
        colorArray.append(NSColor.systemTeal.withAlphaComponent(colorAlpha).cgColor)
        colorArray.append(NSColor.systemYellow.withAlphaComponent(colorAlpha).cgColor)
                
        let ctFont = font
        let characters = forText
                
        // Initialise attributed string
        let attributedString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0)!
        CFAttributedStringReplaceString(attributedString, CFRangeMake(0, 0), characters as CFString)
                
        // Assign the characters typed
        CFAttributedStringSetAttribute(attributedString, CFRangeMake(0, CFStringGetLength(characters as CFString)), kCTFontAttributeName, ctFont)

        // Set the language (hard-coded for now
        CFAttributedStringSetAttribute(attributedString, CFRangeMake(0, CFStringGetLength(characters as CFString)), kCTLanguageAttributeName, ("mr" as NSString))
                
        let ctline = CTLineCreateWithAttributedString(attributedString)
                
        guard let runs = (CTLineGetGlyphRuns(ctline) as [AnyObject]) as? [CTRun] else { return nil }
                
        var resultsString = "" // "\(loadedFont.fontName ?? ""):\n"
                
        var glyphs = [CGGlyph]()
        var positions = [CGPoint]()
        var names = [String]()
        var unicodes = [UInt32]()
        var colors = [CGColor]()
            
        var colorIndex = 0
        
        var glyphCount = 0
        for run in runs {
            let attributes: NSDictionary = CTRunGetAttributes(run)
            let font = attributes[kCTFontAttributeName as String] as! CTFont
            let cgfont = CTFontCopyGraphicsFont(font, nil)
                                            
            // Glyphs in this run
            glyphCount = CTRunGetGlyphCount(run)
            for index in 0..<glyphCount {
                let range = CFRangeMake(index, 1)
                var glyph = CGGlyph()
                CTRunGetGlyphs(run, range, &glyph)
                var unicode:UInt32 = 0
                var glyphName = ""
                var point = CGPoint(
                )
                if glyph == 65535 {
                    glyph = CGGlyph(0)
                    glyphName = "DEL"
                    point = CGPoint(x: 0, y: 0)
                }
                else {
                    glyphName = cgfont.name(for: glyph)! as String
                    CTRunGetPositions(run, range, &point)
                    // Get the Unicode value of this glyph
                    unicode = glyphToUnicode[glyph]?.value ?? 0
                }
                
                // Get the glyph data for drawing
                glyphs.append(glyph)
                names.append(glyphName)
                unicodes.append(unicode)
                colors.append(colorArray[colorIndex])
                //positions.append(CGPoint(x: point.x+50, y: point.y+100))
                positions.append(CGPoint(x: point.x, y: point.y))
                
                colorIndex += 1
                if colorIndex >= colorArray.count {
                    colorIndex = 0
                }
                
                if (resultsString.lengthOfBytes(using: .utf8) > 0 ) {
                    resultsString = resultsString + "\n"
                }
                resultsString = resultsString + "\(index+1). \(glyphName) - \(glyph)"
                
                print ("CT: \(index+1). \(glyphName ) x: \(point.x) y: \(point.y)")
            }
        }
        
        let stringLayoutViewData = StringLayoutViewData()
        stringLayoutViewData.font = ctFont!
        stringLayoutViewData.glyphs = glyphs
        stringLayoutViewData.unicodes = unicodes
        stringLayoutViewData.positions = positions
        stringLayoutViewData.xOffset = 30
        stringLayoutViewData.yOffset = 0 // 0 means let GlyphView calculate
        stringLayoutViewData.names = names
        stringLayoutViewData.count = glyphCount
        stringLayoutViewData.colors = colors //colorArray
        stringLayoutViewData.unicodeString = ""
        stringLayoutViewData.drawMetrics = true
        stringLayoutViewData.displayName = displayName
        stringLayoutViewData.fontVersion = fontVersion
        
        return stringLayoutViewData
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - Harfbuzz layout functions
    // Use Harfbuzz to get the layout data for given string
    // -----------------------------------------------------------------
    
    func getStringLayoutViewDataWithHarfbuzz(forText:String) -> StringLayoutViewData? {
        
        let shapedJson = hbShaper.hbShapeString(forText)
        print ("Shaped JSON: \(shapedJson)")
        /*
        textViewRight.string = ""
        
        if loadedFonts.count == 0 || loadedFonts[0] == nil {
            return
        }
        
        let fontPath    = loadedFonts[0]?.fontPath!
        let fontName    = loadedFonts[0]?.fontName!
        let ctFont      = loadedFonts[0]?.ctFont!
        
        labelTextViewRight.stringValue = "\(fontName!) - HB"
        labelTextViewRight.textColor = NSColor(cgColor: CGCOLOR_SECONDARY)
        
        // Save the typed text
        UserDefaults.init().set(inText.stringValue, forKey: "IN_TEXT")
        
        // CT Font is created only for the display. Position information is
        // obtained from HB
        if fontPath==nil /*|| !loadFontFromPath(path: fontPath!)*/ {
            print("Unable to load font!")
            return
        }
        
        //let hbShape = "/Users/muthu/Projects/harfbuzz-2.6.7/util/hb-shape"
        let hbShape = "/opt/local/bin/hb-shape"
        
        let hexText = inText.stringValue.hexString() //stringToHexArray(string: inText.stringValue)
        //let hasResults = callHarfbuzz(launchPath: "/bin/bash", fontPath: fontPath!,
        //                              arguments: [hbShape, fontPath!, "-u", hexText, "-O", "json"])
        
        let hasResults = callHarfbuzz(launchPath: hbShape, fontPath: fontPath!,
                                      arguments: [fontPath!, "-u", hexText, "-O", "json"])

        
        var resultsString = "" //\(fontName ?? ""):\n"
        
        var glyphs = [CGGlyph]()
        var positions = [CGPoint]()
        var names = [String]()
        
        if hasResults {
            //print ("Glyph dump for \(inText.stringValue) from Harfbuzz")
            var num = 1
            var xPos = 0.0 as Float
            var glyphCount = 0
            for hbResult in hbResults {
                if (resultsString.lengthOfBytes(using: .utf8) > 0 ) {
                    resultsString = resultsString + "\n"
                }
                resultsString = resultsString + "\(num). \(hbResult["g"] ?? "")"
                                
                // print ("HB: \(hbResult["g"] ?? "") => ay: \(hbResult["ay"] ?? 0), ax: \(hbResult["ax"] ?? 0), dy: \(hbResult["dy"] ?? 0), dx: \(hbResult["dx"] ?? 0), cl: \(hbResult["cl"] ?? "")")
                
                let glyph = CTFontGetGlyphWithName(ctFont!, hbResult["g"] as! CFString)
                let glyphName = hbResult["g"] as! String
                
                let y = hbResult["dy"] as! Float
                let x = xPos + (hbResult["dx"] as! Float)
                
                // Using a scale of 10.66666666666667. Is is determined by dividing the ax of ka-grantha by the width of ka-grantha in CoreText above.
                // Need to figure a better way to get this scale
                let scale = 10.66666666666666667 as Float
                let ys = Double((y / scale))
                let xs = Double((x / scale))
                
                print ("HB: \(num). \( glyphName ) x: \(xs) y: \(ys)")
                
                // Get the glyph data for drawing
                glyphs.append(glyph)
                names.append(glyphName)
                positions.append(CGPoint(x: xs, y: ys))
                
                xPos = xPos + (hbResult["ax"] as! Float)
                num  = num+1
                glyphCount = glyphCount + 1
            }
            
            let glyphData = GlyphView.GlyphData(
                font: ctFont!,
                glyphs: glyphs,
                positions: positions,
                xOffset: 30,
                yOffset: 0, // 0 means let GlyphView calculate
                names: names,
                count: glyphCount,
                colors: cboxLeft.state == .on ? [CGCOLOR_SECONDARY] : colors,
                unicodeString: "",
                drawMetrics: true
            )
            
            // Harfbuzz is only called when there is only 1 font (i.e. primary)
            textViewRight.string = resultsString
            
            // Pass the glyphdata for second 'font' as a comparison
            glyphView.glyphData2 = glyphData
        }
 */
        return nil
    }
    
    func callHarfbuzz(fontPath:String, arguments: [String] = []) -> [[String:Any]]? {
        
        /*
        // Return if we can't locate
        let task = Process()
        //task.launchPath = "/opt/local/bin/hb-shape" //launchPath //"/bin/bash" //
        let url = URL(fileURLWithPath: "/Users/muthu/Projects/harfbuzz-2.6.7/util/hb-shape")
        task.executableURL = URL(fileURLWithPath:"/Users/muthu/Projects/harfbuzz-2.6.7/util/hb-shape")// "/opt/local/bin/hb-shape")
        task.arguments = [/*"-c", "/Users/muthu/Projects/harfbuzz-2.6.7/util/hb-shape" "/opt/local/bin/hb-shape",*/ "/Users/muthu/Downloads/AnnaiMN-Regular.ttf", "-u", "006D, 0079, 0020, 0073, 0061, 0076, 0065, 0064, 0020, 0074, 0065, 0078, 0074", "-O", "json"] // arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run() // launch()
        
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        
            var hbResults: [[String:Any]] = []
        

            let jsonResponse = try JSONSerialization.jsonObject(with:data, options: [])
            guard let jsonArray = jsonResponse as? [[String: Any]] else { return nil }
            hbResults = jsonArray
            
            return hbResults

        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
            //showMessage(title: "hb-shape returned error", text: "\(error.localizedDescription)\nCheck file \(fontPath).")
        }
        */

        return nil
    }
    
    // ------------------------------------------------------------
    // MARK: - Utility functions
    // Utility functions
    // ------------------------------------------------------------

    // Taken from here: https://stackoverflow.com/questions/56782339/how-to-get-all-characters-of-the-font-with-ctfontcopycharacterset-in-swift
    func createGlyphToUnicodeMap(ctFont: CTFont) ->  [CGGlyph : UnicodeScalar] {

        let charset = CTFontCopyCharacterSet(ctFont) as CharacterSet

        var glyphToUnicode = [CGGlyph : UnicodeScalar]() // Start with empty map.

        // Enumerate all Unicode scalar values from the character set:
        for plane: UInt8 in 0...16 where charset.hasMember(inPlane: plane) {
            for unicode in UTF32Char(plane) << 16 ..< UTF32Char(plane + 1) << 16 {
                if let uniChar = UnicodeScalar(unicode), charset.contains(uniChar) {

                    // Get glyph for this `uniChar` ...
                    let utf16 = Array(uniChar.utf16)
                    var glyphs = [CGGlyph](repeating: 0, count: utf16.count)
                    if CTFontGetGlyphsForCharacters(ctFont, utf16, &glyphs, utf16.count) {
                        // ... and add it to the map.
                        glyphToUnicode[glyphs[0]] = uniChar
                    }
                }
            }
        }

        return glyphToUnicode
    }
}

func showMessage(title: String, text: String) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = text
    alert.alertStyle = .critical
    alert.addButton(withTitle: "OK")
    alert.runModal()
    //alert.addButton(withTitle: "Cancel")
    //return alert.runModal() == .alertFirstButtonReturn
}
