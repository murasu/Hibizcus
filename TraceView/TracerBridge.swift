//
//  HBTraceInterface.swift
//
//  Created by Muthu Nedumaran on 27/2/21.
//

import Combine
import SwiftUI
import AppKit

struct TVGlyph: Codable {
    let g: Int?         // Glyph ID
    var gn: String?     // Glyph Name
    let u: Int?         // Unicode
    let cl: Int?        // Cluster
    var dx: Float?
    var dy: Float?
    var ax: Float?
    var ay: Float?
    var xb: Float?
    var yb: Float?
    var w: Float?         // Width
    var h: Float?         // Height
}

struct TVGlyphs: Codable {
    var items:[TVGlyph]?
}

struct TVLogItem: Identifiable, Equatable {
    var id = UUID()             // Unique ID
    var traceId = ""            // Id for this trace
    var message = ""            // The message from shaping trace
    var didShape = false        // Flag to indicate if the shaping happned
    var items = [TVGlyph]()     // Data from hb
    
    static func == (lhs: TVLogItem, rhs: TVLogItem) -> Bool {
        return lhs.id == rhs.id
    }
}

class TracerBridge: ObservableObject {
    @Published var hbFont: HBFont = HBFont(filePath: "", fontSize: 40)
    @Published var prevGlyphs = TVGlyphs()
    @Published var prevMessage = ""
    
    @Published var theText: String = ""
    @Published var tvLogItems = [TVLogItem]()

    var traceId = ""
    
    static let shared = TracerBridge()
    
    // this will become SUB and POS
    // to indicate substitution (GSUB and morx) and positioning (GPOS and kerx)
    
    var currentShapingAction = Hibizcus.ShapingTableAction.System
    
    init() {
        set_callback (
            {
                if let ptr = $0 {
                    var retstr = String(cString: ptr)
                    //print("Received: \(retstr)")
                    //Check if this is for the current traceId
                    let markIndex = retstr.firstIndex(of: "|")
                    if  markIndex != nil {
                        let retTraceId = String(retstr.prefix(upTo: markIndex!))
                        //print("Returned traceId: \(retTraceId) | current traceId: \(TracerBridge.shared.traceId)")
                        if retTraceId != TracerBridge.shared.traceId {
                            // This is unlikely
                            //print("Returned traceId \(retTraceId) expired. New one is \(TracerBridge.shared.traceId)")
                            return
                        }
                        retstr = String(retstr.suffix(from: retstr.index(after: markIndex!)))
                    }
                    
                    // str will be in the format <message> <json>\n<json> where the second json contains glyph names"
                    var idx = retstr.firstIndex(of: "\n")
                    if idx != nil {
                        // First part contains message and json with GIDs
                        let str = retstr.prefix(upTo: idx!).trimmingCharacters(in: .whitespacesAndNewlines)
                        // Second part is just json with names
                        let gnstr = retstr.suffix(from: idx!).trimmingCharacters(in: .whitespacesAndNewlines)
                        // Split the first part into message and json, then parse the json
                        idx = str.firstIndex(of: "[")
                        if idx != nil {
                            // message
                            let message = str.prefix(upTo: idx!).trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            // json with gids
                            let JSONGidString = "{\"items\":" + str.suffix(from: idx!).trimmingCharacters(in: .whitespacesAndNewlines) + "}"
                            
                            // Tag the message to say SUB or POS
                            //message = TracerBridge.shared.tagActionTo(message:message)
                            
                            let jsonData = JSONGidString.data(using: .utf8)!
                            do {
                                let decoder = JSONDecoder()
                                var tvGlyphs = try decoder.decode(TVGlyphs.self, from: jsonData)
                                
                                // now get the names
                                // replace g: with gn: so we can reuse the same struct
                                let gnstrep = gnstr.replacingOccurrences(of: "\"g\":", with: "\"gn\":")
                                let JSONGnameString = "{\"items\":" + gnstrep + "}"
                                //print("Getting names from \(JSONGnameString)")
                                let jsonGnameData = JSONGnameString.data(using: .utf8)!
                                let tvGNames = try decoder.decode(TVGlyphs.self, from: jsonGnameData)
                                for i in 0 ..< tvGNames.items!.count {
                                    if tvGNames.items![i].gn != nil {
                                        tvGlyphs.items![i].gn = tvGNames.items![i].gn
                                        //print("  \(tvGlyphs.items![i].g) => \(tvGNames.items![i].gn)")
                                    }
                                }
                                
                                //print("Message: \(message) Items: \(tvGlyphs.items ?? [TVGlyph]())")

                                // Scale the dimensions to facilitate drawing
                                let scale = (Hibizcus.FontScale / (2048/TracerBridge.shared.hbFont.metrics.upem)) * (192/40)
                                for i in 0..<tvGlyphs.items!.count {
                                    let w = tvGlyphs.items![i].w ?? 0
                                    tvGlyphs.items![i].w = w / scale
                                    let h = tvGlyphs.items![i].h ?? 0
                                    tvGlyphs.items![i].h = h / scale
                                    // xb & yb
                                    let xb = tvGlyphs.items![i].xb ?? 0
                                    tvGlyphs.items![i].xb = xb / scale
                                    let yb = tvGlyphs.items![i].yb ?? 0
                                    tvGlyphs.items![i].yb = yb / scale
                                    // ax & ay
                                    let ax = tvGlyphs.items![i].ax ?? 0
                                    tvGlyphs.items![i].ax = ax / scale
                                    let ay = tvGlyphs.items![i].ay ?? 0
                                    tvGlyphs.items![i].ay = ay / scale
                                    // dx & dy
                                    let dx = tvGlyphs.items![i].dx ?? 0
                                    tvGlyphs.items![i].dx = dx / scale
                                    let dy = tvGlyphs.items![i].dy ?? 0
                                    tvGlyphs.items![i].dy = dy / scale
                                }
                                
                                var tvLogItem = TVLogItem()
                                tvLogItem.message = message
                                tvLogItem.traceId = TracerBridge.shared.traceId
                                tvLogItem.items = tvGlyphs.items!
                                
                                /*
                                var flagLastItemAsDidShape = false
                                let pMesg = TracerBridge.shared.prevMessage
                                if pMesg.count > 0 {
                                    // Check if this is a follow up message
                                    if TracerBridge.shared.shapingHappened(message, prevMessage: pMesg, currGlyphs: tvGlyphs, prevGlyphs: TracerBridge.shared.prevGlyphs) {
                                        //print("Yesss! A shaping action happened!")
                                        flagLastItemAsDidShape = true
                                    }
                                } */
                                
                                // Save the glyphs array & the message
                                //TracerBridge.shared.prevGlyphs = tvGlyphs
                                //TracerBridge.shared.prevMessage = message
                                
                                DispatchQueue.main.async {
                                    /*
                                    if flagLastItemAsDidShape {
                                        var tvLogItemPrev = TracerBridge.shared.tvLogItems.last!
                                        tvLogItemPrev.didShape = true
                                        TracerBridge.shared.tvLogItems.removeLast()
                                        TracerBridge.shared.tvLogItems.append(tvLogItemPrev)
                                        tvLogItem.didShape = true
                                    } */
                                    TracerBridge.shared.tvLogItems.append(tvLogItem)
                                    if tvLogItem.message == "final output" {
                                        //print("Final message received and processed:\n\(TracerBridge.shared.tvLogItems)")
                                        print("Here's where I can check and set the flags!")
                                        TracerBridge.shared.updateDidShapeFlag()
                                    }
                                }
                            }
                            catch {
                                print ("JSON PARSE ERROR:\(error.localizedDescription): \n ->> \(JSONGidString) <<-")
                            }
                        }
                    }
                }
            });
    }
    
    func updateDidShapeFlag() {
        if !Thread.isMainThread {
            print("The function updateDidShapeFlag should be called from the Main thread!")
            return
        }
        
        for i in 0 ..< TracerBridge.shared.tvLogItems.count-1 {
            let prevItem = TracerBridge.shared.tvLogItems[i]
            let currItem = TracerBridge.shared.tvLogItems[i+1]
            
            // We track start and end of tables and final output
            if prevItem.message.hasPrefix("start table") || prevItem.message.hasPrefix("end table") {
                TracerBridge.shared.tvLogItems[i].didShape = true
            }
            
            // Also the final output
            if currItem.message=="final output" {
                TracerBridge.shared.tvLogItems[i+1].didShape = true
            }
            
            print("==>Message Prev: \(prevItem.message)")
            let updatedPrevMessage = tagActionTo(message: prevItem.message)
            TracerBridge.shared.tvLogItems[i].message = updatedPrevMessage
            print("   Updated Prev: \(updatedPrevMessage)")
            
            print("==>Message Curr: \(currItem.message)")
            let updatedCurrMessage = tagActionTo(message: currItem.message)
            TracerBridge.shared.tvLogItems[i+1].message = updatedCurrMessage
            print("   Updated Curr: \(updatedCurrMessage)")
            
            if shapingHappened(updatedCurrMessage, prevMessage: updatedPrevMessage, currGlyphs: currItem.items, prevGlyphs: prevItem.items) {
                TracerBridge.shared.tvLogItems[i].didShape = true
                TracerBridge.shared.tvLogItems[i+1].didShape = true
            }
        }
    }
    
    func shapingHappened(_ message:String, prevMessage:String, currGlyphs:[TVGlyph], prevGlyphs:[TVGlyph]) -> Bool {
        if message.hasPrefix("end") {
            // Get the previous message
            if prevMessage.hasPrefix("start") {
                let pMessage = prevMessage.replacingOccurrences(of: "start ", with: "")
                let cMessage = message.replacingOccurrences(of: "end ", with: "")
                //print("Prev == Curr : \(pMessage) == \(cMessage)")
                if pMessage == cMessage {
                    // compare the previous data with the current one
                    switch currentShapingAction {
                    case Hibizcus.ShapingTableAction.Subtituting,
                         Hibizcus.ShapingTableAction.System :
                        // Compare glyph count
                        if currGlyphs.count != prevGlyphs.count {
                            return true
                        }
                        // Compare the order of the glyphs
                        //print("   Checking glyph order")
                        for i in 0 ..< currGlyphs.count {
                            var vc = 0; var vp = 0;
                            if currGlyphs[i].g != nil {
                                vc = currGlyphs[i].g!
                                vp = prevGlyphs[i].g!
                            } else {
                                vc = currGlyphs[i].u!
                                vp = prevGlyphs[i].u!
                            }
                            if vc != vp {
                                //print("      glyphs at index \(i) are not the same \(vc) != \(vp)")
                                //print("      Substitution happened!")
                                return true
                            }
                        }
                    case Hibizcus.ShapingTableAction.Positioning :
                        // Compare the offset and advancement of the glyphs
                        //print("   Checking glyph positions")
                        var happened = false
                        for i in 0 ..< currGlyphs.count {
                            //print("   curr \(i) => dx \(currGlyphs[i].dx!), dy \(currGlyphs[i].dy!), ax \(currGlyphs[i].ax!), ay \(currGlyphs[i].ay!)")
                            //print("   prev \(i) => dx \(prevGlyphs[i].dx!), dy \(prevGlyphs[i].dy!), ax \(prevGlyphs[i].ax!), ay \(prevGlyphs[i].ay!)")
                            if currGlyphs[i].dx! != prevGlyphs[i].dx! {
                                //print("      dx is not the same for glyph at \(i) \(currGlyphs[i].dx!) != \(prevGlyphs[i].dx!)")
                                happened = true
                            }
                            else if currGlyphs[i].dy! != prevGlyphs[i].dy! {
                                //print("      dy is not the same for glyph at \(i) \(currGlyphs[i].dy!) != \(prevGlyphs[i].dy!)")
                                happened = true
                            }
                            else if currGlyphs[i].ax! != prevGlyphs[i].ax! {
                                //print("      ax is not the same for glyph at \(i) \(currGlyphs[i].ax!) != \(prevGlyphs[i].ax!)")
                                happened = true
                            }
                            else if currGlyphs[i].ay! != prevGlyphs[i].ay! {
                                //print("      ay is not the same for glyph at \(i) \(currGlyphs[i].ay!) != \(prevGlyphs[i].ay!)")
                                happened = true
                            }
                            if happened {
                                //print("      Positioning happened!")
                                return happened
                            }
                        }
                    }
                }
            }
        }
        
        return false
    }
        
    func tagActionTo(message: String) -> String {
        switch (message) {
        case "start table GSUB" :
            currentShapingAction = Hibizcus.ShapingTableAction.Subtituting
            print("   Starting Substitution action")
        case "start table GPOS" :
            currentShapingAction = Hibizcus.ShapingTableAction.Positioning
            print("   Starting Positioning action")
        case "start preprocess-text",
             "start reorder",
             "final output" :
            currentShapingAction = Hibizcus.ShapingTableAction.System
            print("   Starting System action")
        case "start reordering indic initial",
             "start reordering indic final" :
            print("   Continue with current shaping action")
        default:
            if message.hasPrefix("start lookup") || message.hasPrefix("end lookup") {
                var tag = ""
                switch currentShapingAction {
                case Hibizcus.ShapingTableAction.Subtituting:
                    tag = "GSUB"
                case Hibizcus.ShapingTableAction.Positioning:
                    tag = "GPOS"
                default:
                    tag = ""
                }
                return message.replacingOccurrences(of: "lookup", with: "\(tag) lookup")
            }
            else if message.contains("start chainsubtable") {
                currentShapingAction = Hibizcus.ShapingTableAction.Subtituting
                return message.replacingOccurrences(of: "start chainsubtable", with: "start morx subtable") // "start morx chainsubtable")
            }
            else if message.contains("end chainsubtable") {
                return message.replacingOccurrences(of: "end chainsubtable", with: "end morx subtable") // "end morx chainsubtable")
            }
            else if message.contains("start subtable") {
                currentShapingAction = Hibizcus.ShapingTableAction.Positioning
                return message.replacingOccurrences(of: "start subtable", with: "start kerx subtable")
            }
            else if message.contains("end subtable") {
                return message.replacingOccurrences(of: "end subtable", with: "end kerx subtable")
            }
            else {
                //print("Unhandled message: \(message)")
            }
        }
        return message
    }
    
    func startTrace() {
        tvLogItems.removeAll()
        if theText.count == 0 {
            traceId = ""
            return
        }
        // Initialise trace id
        traceId = NSDate().timeIntervalSince1970.debugDescription
        print("Tracing \(theText) with traceId \(traceId)")
        let selectedLanguageCode = hbFont.languageCode(forName: hbFont.selectedLanguage)
        if hbFont.fileUrl != nil {
            hbFont.fileUrl!.withUnsafeFileSystemRepresentation { cStr in
                print("Starting to trace with \(cStr!), \(theText), \(hbFont.selectedScript), \(selectedLanguageCode), ")
                start_trace_with_callback(cStr, theText, hbFont.selectedScript, selectedLanguageCode, traceId);
            }
        }
        else {
            print("Font file url is nil")
        }
    }
}


