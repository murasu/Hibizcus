//
//  Hibizcus.swift
//
//  Created by Muthu Nedumaran on 15/2/21.
//

import Foundation
import SwiftUI

struct Hibizcus {

    struct UIString {
        static let TestStringPlaceHolder                = "Type the string you want to test"
        static let DragAndDropTwoFontFiles              = "Drag font files and drop them here.\nYou can drop up to two font files,\none at a time."
        static let DragAndDropOneFontFile               = "Drag a font file and drop it here."
        static let DragAndDropGridItemOrTwoFontFiles    = "Drag a cluster or word item and drop it here\nOR\ndrag font files and drop them here.\nYou can drop up to two font files,\none at a time."
    }
    
    enum Position {
        case None, Prefix, Base, BaseEx, Nukta, Matra, Sign, Joiner
    }
    
    enum ShapingEngine {
        case CoreText, Harfbuzz
    }
    
    enum ShapingTableAction {
        case System, Subtituting, Positioning
    }
    
    struct Key {
        static let SVString                     = "sv.string"           // The test string in StringViewer
        static let TVString                     = "tv.string"           // The test string in TraceViewer
        static let WVString                     = "wv.string"
        static let SelectedLanguages            = "selected.languages"
        static let ToggleFont                   = "toggle.fonts"
    }
    
    static let FontScale: Float                 = 10.66666666666666667
    
    struct Shaper {
        static let CoreText                     = "CoreText"
        static let Harfbuzz                     = "Harfbuzz"
        static let None                         = "None"
        static let DefaultLanguageName          = "Default"
        static let DefaultLanguageCode          = "dflt"
        static let DefaultLanguage              = Language(langName: DefaultLanguageName, langId: DefaultLanguageCode, selected: true)
    }
    
    struct FontColor {
        static let MainFontColor                = NSColor.systemGreen.withAlphaComponent(0.6).cgColor
        static let CompareFontColor             = NSColor.systemRed.withAlphaComponent(0.6).cgColor
        static let MainFontUIColor              = Color(NSColor.systemGreen) 
        static let CompareFontUIColor           = Color(NSColor.systemRed)
    }
    
    // The color array used to draw glyphs
    static let colorAlpha:CGFloat = 0.70
    static let colorArray = [
        NSColor.systemRed.withAlphaComponent(colorAlpha).cgColor,
        NSColor.systemBlue.withAlphaComponent(colorAlpha).cgColor,
        NSColor.systemBrown.withAlphaComponent(colorAlpha).cgColor,
        NSColor.systemGreen.withAlphaComponent(colorAlpha).cgColor,
        NSColor.systemOrange.withAlphaComponent(colorAlpha).cgColor,
        NSColor.systemPink.withAlphaComponent(colorAlpha).cgColor,
        NSColor.systemPurple.withAlphaComponent(colorAlpha).cgColor,
        NSColor.systemTeal.withAlphaComponent(colorAlpha).cgColor,
        NSColor.systemYellow.withAlphaComponent(colorAlpha).cgColor
    ]
    static let AnchorColor = NSColor.textColor.withAlphaComponent(0.5).cgColor
}

func defaultLanguage(forScript: String) -> String {
    // This sould be configured in an external file
    switch forScript.lowercased() {
    case "balinese" :
        return "Balinese"
    case "batak" :
        return "Batak"
    case "bengali" :
        return "Bengali"
    case "brahmi" :
        return "Sanskrit"
    case "buginese" :
        return "Buginese"
    case "devanagari" :
        return "Hindi"
    case "grantha" :
        return "Sanskrit"
    case "gujarati" :
        return "Gujarati"
    case "gurmukhi" :
        return "Punjabi"
    case "javanese" :
        return "Javanese"
    case "kannada" :
        return "Kannada"
    case "khmer" :
        return "Khmer"
    case "lao" :
        return "Lao"
    case "malayalam" :
        return "Malayalam"
    case "meeteimayek" :
        return "Meetei"
    case "myanmar" :
        return "Myanmar"
    case "odia" :
        return "Odia"
    case "rejang" :
        return "Rejang"
    case "sinhala" :
        return "Sinhala"
    case "sundanese" :
        return "Sundanese"
    case "tamil" :
        return "Tamil"
    case "telugu" :
        return "Telugu"
    case "thaana" :
        return "Divehi"
    case "thai" :
        return "Thai"
    case "tirhuta" :
        return "Maithili"
    default:
        return ""
    }
}

// Clipboard functions
func copyTextToClipboard(textToCopy: String) {
    NSPasteboard.general.clearContents()
    if !NSPasteboard.general.setString(textToCopy, forType: NSPasteboard.PasteboardType.string) {
        print("Error setting string in pasteboard")
    }
    else {
        postNotification(title: "Hibizcus", message: "'\(textToCopy)' copied to clipboard")
    }
}

// User Notifications

import UserNotifications

func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { granted, error in
        if error != nil {
            print ("Request notifications permission Error");
        }
        if granted {
            print ("Notifications allowed");
        }
        else {
            print ("Notifications denied");
        }
    }
}

func postNotification(title: String, message: String) {
    let notificationCenter = UNUserNotificationCenter.current()
    notificationCenter.getNotificationSettings { (settings) in
        if settings.authorizationStatus == .authorized {
            // Create the notification content
            let content = UNMutableNotificationContent()
            content.title   = title
            content.body    = message
            content.badge   = false
            
            // Time interval for the banner to appear. Can't be 0?
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            
            // Create the request
            let uuidString = UUID().uuidString
            let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
            
            // Schedule the request with the system.
            notificationCenter.add(request, withCompletionHandler: { (error) in
                if error != nil {
                    // Something went wrong
                    print("Something went wrong: \(error!.localizedDescription)")
                }
            })
        }
        else {
            print("Notifications not allowed. Request for permission")
            requestNotificationPermission()
        }
    }
}
    
// Custom extensions

public extension Color {

    #if os(macOS)
    static let background = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.underPageBackgroundColor)
    static let tertiaryBackground = Color(NSColor.controlBackgroundColor)
    #else
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    #endif
}

extension String {
    func hexString() -> String {
        var hexText:String = ""
        if self.count == 0 {
            return " "
        }
        for c in self.unicodeScalars {
            if hexText.lengthOfBytes(using: .utf8) > 0 {
                hexText = hexText + ", "
            }
            hexText = hexText + String(format:"%04X",c.value)
        }
        return hexText
    }
    
    // Truncate String 
    // https://gist.github.com/budidino/8585eecd55fd4284afaaef762450f98e
    enum TruncationPosition {
        case head
        case middle
        case tail
    }

    func truncated(limit: Int, position: TruncationPosition = .tail, leader: String = "…") -> String {
        guard self.count > limit else { return self }

        switch position {
        case .head:
            return leader + self.suffix(limit)
        case .middle:
            let headCharactersCount = Int(ceil(Float(limit - leader.count) / 2.0))

            let tailCharactersCount = Int(floor(Float(limit - leader.count) / 2.0))
            
            return "\(self.prefix(headCharactersCount))\(leader)\(self.suffix(tailCharactersCount))"
        case .tail:
            return self.prefix(limit) + leader
        }
    }
    
    /*
    func countOfSpacingLetters() -> Int {
        var c = 0
        
        for u in self.unicodeScalars {
            if !"ஂ்".unicodeScalars.contains(u) {
                //print ("\(u) - is a mark")
                c += 1
            }
        }
        
        return c
    } */
}

// From:
// https://stackoverflow.com/questions/50006899/dictionary-extension-that-swaps-keys-values-swift-4-1
extension Dictionary where Value : Hashable {

    func swapKeyValues() -> [Value : Key] {
        assert(Set(self.values).count == self.keys.count, "Values must be unique")
        var newDict = [Value : Key]()
        for (key, value) in self {
            newDict[value] = key
        }
        return newDict
    }
}

// NSView
extension NSView {
    
    func drawLine(inContext:CGContext, fromPoint:CGPoint, toPoint:CGPoint, lineWidth:CGFloat, lineColor:CGColor) {
        inContext.setLineWidth(lineWidth)
        inContext.setStrokeColor(lineColor)
        inContext.move(to: fromPoint)
        inContext.addLine(to: toPoint)
        inContext.strokePath()
    }

    func drawMetricLinesForFont(forFont:CTFont, inContext: CGContext, baseLine:CGFloat, lineColor:CGColor, labelXPos: LabelPosition, drawUnderlinePos: Bool) {
        let nsFont = forFont as NSFont // slData.font! as NSFont
        //let yOffset = /*slData.yOffset > 0 ? slData.yOffset : */getYOffsetFor(font: slData.font! as NSFont)

        // Baseline
        drawMetricLine(atY: baseLine, inContext: inContext, label:"base", lx:labelXPos, ly:1, color: lineColor)
        
        // Ascender
        drawMetricLine(atY: baseLine+nsFont.ascender, inContext: inContext, label:"asc", lx:labelXPos, ly:1, color: lineColor)
        
        // Descender
        drawMetricLine(atY: baseLine+nsFont.descender, inContext: inContext, label:"dec", lx:labelXPos, ly:0, color: lineColor)

        // xHeight
        drawMetricLine(atY: baseLine+nsFont.xHeight, inContext: inContext, label:"x", lx:labelXPos, ly:1, color: lineColor)
        
        // CapHeight
        drawMetricLine(atY: baseLine+nsFont.capHeight, inContext: inContext, label:"cap", lx:labelXPos, ly:1, color: lineColor)

        // Underline
        if drawUnderlinePos {
            drawMetricLine(atY: baseLine+nsFont.underlinePosition, inContext: inContext, label:"ul", lx:labelXPos, ly:0, color: lineColor)
        }
    }
    
    func drawMetricLine(atY:CGFloat, inContext:CGContext, label:String, lx:LabelPosition, ly:Int, color:CGColor) {
        // Draw the line
        drawLine(inContext: inContext, fromPoint: CGPoint(x:0, y:atY), toPoint: CGPoint(x:bounds.size.width, y:atY), lineWidth: 0.5, lineColor: color) // CGColor(gray: 0.8, alpha: 0.8))
        
        // Label attributes
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = lx == .left ? .left : .right
        let attributes: [NSAttributedString.Key : Any] = [
            .paragraphStyle: paragraphStyle,
            .font: NSFont.init(name: "Monaco", size: 10)!,
            .foregroundColor: NSColor.init(cgColor:color)!// NSColor.white
        ]
        
        let labelSize = label.size(withAttributes: attributes)
        let padding:CGFloat = 3.0
        let xpos = lx == .left ? padding : self.bounds.width - labelSize.width - padding
        let ypos = ly == 1 ? atY : atY - labelSize.height
        
        // Daww the label
        // TODO: Position the labels based on lx and ly
        label.draw(at: CGPoint(x: xpos, y: ypos), withAttributes: attributes)
        
        // there is no promise that the text matrix will be identity before calling the next draw
        // see this post: https://stackoverflow.com/questions/53047093/swift-text-draw-method-messes-up-cgcontext
        inContext.textMatrix = .identity
    }
    
    func drawRoundedRect(rect: CGRect, inContext context: CGContext?, radius: CGFloat, borderColor: CGColor, fillColor: CGColor, strokeWidth:CGFloat=1.0) {
                
        let path = CGMutablePath()
        
        path.move( to: CGPoint(x:  rect.midX, y:rect.minY ))
        path.addArc( tangent1End: CGPoint(x: rect.maxX, y: rect.minY ),
                     tangent2End: CGPoint(x: rect.maxX, y: rect.maxY), radius: radius)
        path.addArc( tangent1End: CGPoint(x: rect.maxX, y: rect.maxY ),
                     tangent2End: CGPoint(x: rect.minX, y: rect.maxY), radius: radius)
        path.addArc( tangent1End: CGPoint(x: rect.minX, y: rect.maxY ),
                     tangent2End: CGPoint(x: rect.minX, y: rect.minY), radius: radius)
        path.addArc( tangent1End: CGPoint(x: rect.minX, y: rect.minY ),
                     tangent2End: CGPoint(x: rect.maxX, y: rect.minY), radius: radius)
        path.closeSubpath()
        
        context?.setLineWidth(strokeWidth)
        context?.setFillColor(fillColor)
        context?.setStrokeColor(borderColor)
        
        context?.addPath(path)
        context?.drawPath(using: .fillStroke)
    }
}


extension Data {
    // A hexadecimal string representation of the bytes.
    // Taken from https://stackoverflow.com/questions/39075043/how-to-convert-data-to-hex-string-in-swift/52600783#52600783
    // On 2021-03-23
    func hexEncodedString() -> String {
        let hexDigits = Array("0123456789abcdef".utf16)
        var hexChars = [UTF16.CodeUnit]()
        hexChars.reserveCapacity(count * 2)
        
        for byte in self {
            let (index1, index2) = Int(byte).quotientAndRemainder(dividingBy: 16)
            hexChars.append(hexDigits[index1])
            hexChars.append(hexDigits[index2])
        }
        
        return String(utf16CodeUnits: hexChars, count: hexChars.count)
    }
}

extension String {
    // A data representation of the hexadecimal bytes in this string.
    // Taken from https://stackoverflow.com/questions/39075043/how-to-convert-data-to-hex-string-in-swift/52600783#52600783
    func hexDecodedData() -> Data {
        // Get the UTF8 characters of this string
        let chars = Array(utf8)
        
        // Keep the bytes in an UInt8 array and later convert it to Data
        var bytes = [UInt8]()
        bytes.reserveCapacity(count / 2)
        
        // It is a lot faster to use a lookup map instead of strtoul
        let map: [UInt8] = [
            0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, // 01234567
            0x08, 0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 89:;<=>?
            0x00, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x00, // @ABCDEFG
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00  // HIJKLMNO
        ]
        
        // Grab two characters at a time, map them and turn it into a byte
        for i in stride(from: 0, to: count, by: 2) {
            let index1 = Int(chars[i] & 0x1F ^ 0x10)
            let index2 = Int(chars[i + 1] & 0x1F ^ 0x10)
            bytes.append(map[index1] << 4 | map[index2])
        }
        
        return Data(bytes)
    }
}

extension URL {
    public var queryParameters: [String: String]? {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
}

