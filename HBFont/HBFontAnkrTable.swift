//
//  HBFontAnkrTable.swift
//
//  Created by Muthu Nedumaran on 4/9/20.
//  Copyright © 2020 Murasu Systems Sdn bhd. All rights reserved.
//

import Cocoa
import BinarySwift

class HBFontAnkrTable: NSObject {
    
    var ankrData:Data?
    var ankrDict = Dictionary<UInt16, Array<Dictionary<String, Int16>>>()
    

    func getAnchorPointsAsXML(fromFont: CTFont) -> String {
        //TODO: Edit this to return XML
        if parseAnkr() {
            return "I should return an XML string here!"
        }
        
        return ""
    }
    
    // Returns [glyphName:[CGPoint]]
    func getAnchorPoints(fromFont: CTFont, scale: Float) -> [String:[CGPoint]]? {
        let ankrTable = CTFontCopyTable(fromFont, CTFontTableTag(kCTFontTableAnkr), CTFontTableOptions(rawValue: 0))
        if ankrTable == nil {
            return nil
        }
        
        self.ankrData = ankrTable! as Data

        var allAnchors = [String:[CGPoint]]()
        let cgfont = CTFontCopyGraphicsFont(fromFont, nil)
        
        do {
            let data = BinaryData(data: ankrData!)
            let _:UInt16 = try data.get(0)  // Version, currently always 0
            let _:UInt16 = try data.get(2)  // Flags, currently always 0
            let lookupTableOffset:UInt32 = try data.get(4)
            let glyphDataTableOffset:UInt32 = try data.get(8)
            
            var idx:Int = Int(lookupTableOffset)
            let format:UInt16 = try data.get(idx)
            idx += 2
            if  format == 4 {
                let _:UInt16 = try data.get(idx) // not interested in lookupSize
                idx += 2
                let numUnits:UInt16 = try data.get(idx)
                idx += 2
                let _:UInt16 = try data.get(idx) // not interested in searchRange
                idx += 2
                let _:UInt16 = try data.get(idx) // not interested in entrySelector
                idx += 2
                let _:UInt16 = try data.get(idx) // not interested in rangeShift
                idx += 2
                                
                var ofs = Int(glyphDataTableOffset)
                for _ in 0..<numUnits {
                    let lastGlyphId:UInt16 = try data.get(idx); idx+=2
                    let firstGlyphId:UInt16 = try data.get(idx); idx+=2
                    let _:UInt16 = try data.get(idx); idx+=2 // not interested in lookupValue
                    
                    if firstGlyphId >= 0xFFFF {
                        break
                    }
                    
                    for glyphId in firstGlyphId...lastGlyphId {
                        let glyphName = cgfont.name(for: glyphId)! as String
                        let anchorCount:UInt32 = try data.get(ofs);
                        ofs += 4
                        for _ in 0..<anchorCount {
                            let x:Int16 = try data.get(ofs); ofs += 2
                            let y:Int16 = try data.get(ofs); ofs += 2
                            let point = CGPoint(x: CGFloat(Float(x)/scale), y: CGFloat(Float(y)/scale))
                            
                            if allAnchors[glyphName] == nil {
                                allAnchors[glyphName] = [point]
                            } else {
                                if !(allAnchors[glyphName]?.contains(point))! {
                                    allAnchors[glyphName]?.append(point)
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            print("An error occured while parsing ankr table: \(error.localizedDescription)")
        }
        
        return allAnchors
    }
    
    private func parseAnkr() -> Bool {
        
        do {
            let data = BinaryData(data: ankrData!)
            let _:UInt16 = try data.get(0)  // Version, currently always 0
            let _:UInt16 = try data.get(2)  // Flags, currently always 0
            let lookupTableOffset:UInt32 = try data.get(4)
            let glyphDataTableOffset:UInt32 = try data.get(8)
            
            var idx:Int = Int(lookupTableOffset)
            let format:UInt16 = try data.get(idx)
            idx += 2
            if  format == 4 {
                let _:UInt16 = try data.get(idx) // not interested in lookupSize
                idx += 2
                let numUnits:UInt16 = try data.get(idx)
                idx += 2
                let _:UInt16 = try data.get(idx) // not interested in searchRange
                idx += 2
                let _:UInt16 = try data.get(idx) // not interested in entrySelector
                idx += 2
                let _:UInt16 = try data.get(idx) // not interested in rangeShift
                idx += 2
                                
                var ofs = Int(glyphDataTableOffset)
                for _ in 0..<numUnits {
                    //var anchors = Dictionary<String, Int>()
                    
                    let lastGlyphId:UInt16 = try data.get(idx); idx+=2
                    let firstGlyphId:UInt16 = try data.get(idx); idx+=2
                    let _:UInt16 = try data.get(idx); idx+=2 // not interested in lookupValue
                    
                    if firstGlyphId >= 0xFFFF {
                        break
                    }
                    
                    for glyphId in firstGlyphId...lastGlyphId {
                        let anchorCount:UInt32 = try data.get(ofs);
                        print("\t<glyphData glyphRefID=\"\(glyphId)\" nPoints=\"\(anchorCount)\" >")
                        ofs += 4
                        var anchors = Array<Dictionary<String, Int16>>()
                        for i in 0..<anchorCount {
                            let x:Int16 = try data.get(ofs); ofs += 2
                            let y:Int16 = try data.get(ofs); ofs += 2
                            let anchor = ["x":x, "y":y]
                            anchors.append(anchor)
                            print ("\t\t<point index=\"\(i)\" x=\"\(x)\" y=\"\(y)\" />")
                        }
                        ankrDict[glyphId] = anchors
                        print("\t</glyphData>")
                    }
                }
            }
        } catch {
            return false
        }
        
        return true
    }
}
