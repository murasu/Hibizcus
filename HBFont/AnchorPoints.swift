//
//  AnchorPoints.swift
//
//  Created by Muthu Nedumaran on 24/2/21.
//

import Foundation


class AnchorPoints {
    var allAnchors = [String:[CGPoint]]()
    private var scale: Float = Hibizcus.FontScale 

    func getAnchorPoints(fromFile: UnsafePointer<Int8> /*fromFile: String*/, useScale:Float) -> [String:[CGPoint]] {
        // TODO: Explore possibility of getting just the GPOS data instead of the entire font
        // Call our C function to get the json data for the entire font
        let jsonData = String(cString:get_data_as_json_from_font_file(fromFile))
        
        self.scale = useScale 
        
        let size = jsonData.count
        print("Json file of length \(size) fetched!")

        do {
            // Decode data to a Dictionary<String, Any> object
            guard let dictionary = try JSONSerialization.jsonObject(with: Data(jsonData.utf8), options: []) as? [String: Any] else {
                print("Could not cast JSON content as a Dictionary<String, Any>")
                return allAnchors
            }
            // Print the lookups in the GPOS table
            let gpos = dictionary["GPOS"] as? Dictionary<String, AnyObject>
            
            if gpos == nil {
                return allAnchors
            }
            
            let lookups = gpos!["lookups"] as? Dictionary<String, AnyObject>
            let luOrder = gpos!["lookupOrder"] as? [String]
            
            for lookupName in luOrder! {
                let lookup = lookups![lookupName] as? Dictionary<String, AnyObject>
                let lookupType = lookup!["type"] as! String
                switch lookupType {
                case "gpos_pair" :
                    //dumpGposPairAsKerxDist(lookup: lookup!)
                    break;
                case "gpos_mark_to_base" :
                    collectAnchorsFrom(lookup: lookup!, isMark2Mark: false)
                    break;
                case "gpos_mark_to_mark" :
                    collectAnchorsFrom(lookup: lookup!, isMark2Mark: true)
                    break;
                default:
                    print("Unknown lookupType")
                    break;
                }
            }
        } catch {
            print("Error reading font \(fromFile) : \(error.localizedDescription)")
        }

        return allAnchors
    }
    
    func collectAnchorsFrom(lookup: Dictionary<String, AnyObject>, isMark2Mark: Bool) {
        let subtables = lookup["subtables"] as! Array<Dictionary<String, Any>>
        
        for subtable in subtables {
            let marks = subtable["marks"] as! Dictionary<String, Any>
            let bases = subtable["bases"] as! Dictionary<String, Any>
            
            // Doing Marks
            for (mark, value) in marks {
                let anchor = value as! Dictionary<String, Any>
                // Get the x,y position
                let x = anchor["x"] as! Float
                let y = anchor["y"] as! Float
                
                let point = CGPoint(x: CGFloat(x/scale), y: CGFloat(y/scale))
                if allAnchors[mark] == nil {
                    allAnchors[mark] = [point]
                } else {
                    if !(allAnchors[mark]?.contains(point))! {
                        allAnchors[mark]?.append(point)
                    }
                }
            }
            
            // Doing Bases
            for (base, value) in bases {
                let anchors = value as! Dictionary<String, Any>
                for (_, position) in anchors {
                    // Get the x,y position
                    let pos = position as! Dictionary<String, Any>
                    let x = pos["x"] as! Float
                    let y = pos["y"] as! Float
                    
                    let point = CGPoint(x: CGFloat(x/scale), y: CGFloat(y/scale))
                    if allAnchors[base] == nil {
                        allAnchors[base] = [point]
                    } else {
                        if !(allAnchors[base]?.contains(point))! {
                            allAnchors[base]?.append(point)
                        }
                    }
                }
            }
        }
    }
}
