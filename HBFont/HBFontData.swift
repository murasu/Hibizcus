//
//  HBFontData.swift
//
//  Created by Muthu Nedumaran on 4/3/21.
//

import Foundation

class HBFontData {
    var dataDict:[String: Any]?
    
    init(pathAsCString: UnsafePointer<Int8>) {
        dataDict = loadFont(pathAsCString: pathAsCString)
    }
    
    private func loadFont(pathAsCString: UnsafePointer<Int8>) -> [String: Any]? {
        let jsonData = String(cString:get_data_as_json_from_font_file(pathAsCString))
        let size = jsonData.count
        print("Json file of length \(size) fetched!")

        do {
            // Decode data to a Dictionary<String, Any> object
            guard let dictionary = try JSONSerialization.jsonObject(with: Data(jsonData.utf8), options: []) as? [String: Any] else {
                print("Could not cast JSON content as a Dictionary<String, Any>")
                return nil
            }
            
            return dictionary
        }
        catch {
            //print("Error reading font \(fontPath ?? "") : \(error.localizedDescription)")
            print("Error reading font : \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func getGlyfData(forGlyphName:String) -> (width:Int, glyf:String)? {
        let glyfData = dataDict?["glyf"] as? [String:Any]
        if glyfData != nil {
            let thisGlyf = glyfData![forGlyphName] as? [String:Any] ?? [String:Any]()
            let advanceWidth = thisGlyf["advanceWidth"] as? Int ?? 0
            var glyfString = ""
            if advanceWidth > 0 {
                let contours = thisGlyf["contours"] as? [Any]
                if contours != nil {
                    for contour in contours! {
                        glyfString += "\(contour)".replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: "")
                        
                    }
                }
            }
            return (width:advanceWidth, glyf:glyfString)
        }
        
        return nil
    }
}
