//
//  GlyphsView.swift
//  OpenRecentDocument
//
//  Created by Muthu Nedumaran on 25/2/21.
//

import Cocoa
import Combine
import SwiftUI

class TraceRowView: NSView {
    let glyphNamePointSize:CGFloat = 10
    let frameColor = NSColor.textColor.withAlphaComponent(0.1).cgColor
    let metricLineColor = NSColor.textColor.withAlphaComponent(0.15).cgColor

    var tvLogItem:TVLogItem? {
        didSet{
            needsDisplay = true
        }
    }
    
    var ctFont:CTFont? {
        didSet{
            needsDisplay = true
        }
    }
    
    var viewOptions:TraceViewOptions = TraceViewOptions() {
        didSet {
            needsDisplay = true
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame:frameRect);
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // The drawing happens here!
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
                
        if tvLogItem == nil || ctFont == nil {
            return
        }
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
                
        let baseLine: CGFloat   = computeBaseLine()
        let cellWidth: CGFloat  = getMaxGlyphWidth()
        let xHeight: CGFloat    = baseLine + CTFontGetXHeight(ctFont!)

        //print("Message: \(tvLogItem?.message)")
        let logMessage = tvLogItem?.message ?? ""
        if logMessage == "start reorder" || logMessage == "end reorder" || logMessage.contains("preprocess") {
            print("Handling system lookup: '\(logMessage)'")

            //print("   Handling as system: Message: \(tvLogItem?.message)")
            NSColor.underPageBackgroundColor.setFill()
            bounds.fill()
            drawSystemLog(context: context, cellWidth: cellWidth, baseLine: baseLine)
            return
        }
        
        if logMessage.contains("reorder") || logMessage.contains("table GSUB") || logMessage.contains("table GPOS") {
            NSColor.alternatingContentBackgroundColors[1].setFill() // underPageBackgroundColor.setFill()
        }
        else {
            NSColor.alternatingContentBackgroundColors[0].setFill() // textBackgroundColor.setFill()
        }
        
        bounds.fill()

        // For Positioning lookups, draw the glyps with positions
        if logMessage.contains("GPOS") || logMessage.contains("kerx subtable") ||  logMessage == "final output" {
            print("Handling positioning lookup: \(logMessage)")
            let hPadding:CGFloat = 10
            var x:CGFloat = hPadding
            var y:CGFloat = baseLine
            
            // Calculate the width so we can draw the baseline and xheight
            for item in tvLogItem!.items {
                if item.g != nil {
                    x += CGFloat(item.ax!)
                }
            }
            x += (2*hPadding) // padding
            
            // Draw the xHeight and baseline
            drawMetricsLines(context: context, xStart: 0, cellWidth: x, baseLine: baseLine, xHeight: xHeight)
            
            x = hPadding
            for item in tvLogItem!.items {
                if item.g != nil {
                    //print("\(item.gn!) = dx,dy \(item.dx!),\(item.dy!) | ax,ay \(item.ax!) \(item.ay!) | xb,yb \(item.xb!) \(item.yb!)")
                    var fillColor = NSColor.textColor.cgColor
                    if viewOptions.showCluster && item.cl != nil {
                        var cluster = item.cl!
                        //print("Cluster = \(cluster) ... Max = Hibizcus.colorArray.count ")
                        if cluster >= Hibizcus.colorArray.count {
                            cluster = cluster % (Hibizcus.colorArray.count)
                            //print("Updated Cluster = \(cluster)")
                        }
                        fillColor = Hibizcus.colorArray[cluster]
                    }
                    context.setFillColor(fillColor) // NSColor.orange.cgColor)
                    
                    var g = [CGGlyph]()
                    g.append(CGGlyph(item.g!))
                    var p = [CGPoint]()
                    p.append(CGPoint(x:x+CGFloat(item.dx!), y:y+CGFloat(item.dy!)))
                    //p.append(CGPoint(x:x, y:y))

                    CTFontDrawGlyphs(ctFont!, g, p, 1, context)
                    
                    x += CGFloat(item.ax!)
                    y += CGFloat(item.ay!)
                }
            }
            
            // Draw the vertical line
            x += (2*hPadding) // padding
            drawLine(inContext: context, fromPoint: CGPoint(x: x, y: 0), toPoint: CGPoint(x: x, y: self.bounds.height), lineWidth: 1, lineColor: frameColor)
            
            return
        }

        // For Substitutions, draw the glyphs into cells
        print("Handling substitution lookup: '\(logMessage)'")
        var x:CGFloat = 0
        var xpad:CGFloat = x
        var xsb:CGFloat = 0
        for item in tvLogItem!.items {
            if item.g != nil {
                // Draw the xHeight and baseline
                drawMetricsLines(context: context, xStart: x, cellWidth: cellWidth, baseLine: baseLine, xHeight: xHeight)
                
                var fillColor = NSColor.textColor.cgColor
                if viewOptions.showCluster && item.cl != nil {
                    var cluster = item.cl!
                    //print("Cluster = \(cluster) ... Max = Hibizcus.colorArray.count ")
                    if cluster >= Hibizcus.colorArray.count {
                        cluster = cluster % (Hibizcus.colorArray.count)
                        //print("Updated Cluster = \(cluster)")
                    }
                    fillColor = Hibizcus.colorArray[cluster]
                }
                context.setFillColor(fillColor) // NSColor.orange.cgColor)
                let glyphs = [CGGlyph(item.g!)]
                // Calculate the padding
                xpad = x + CGFloat((cellWidth-CGFloat(item.w!))/2)
                // Offset the sidebearing
                xsb = 0 - CGFloat(item.xb!)
                CTFontDrawGlyphs(ctFont!, glyphs, [CGPoint(x: xpad+xsb, y: baseLine)], 1, context)
            
                // Draw vertical like at the end of the cell
                drawLine(inContext: context, fromPoint: CGPoint(x: x+cellWidth, y: 0), toPoint: CGPoint(x: x+cellWidth, y: self.bounds.height), lineWidth: 1, lineColor: frameColor)
                // Draw box around glyph
                //drawRoundedRect(rect: CGRect(x: xpad, y: 0, width: CGFloat(item.w!), height: self.bounds.height),
                //                inContext: context, radius: 0, borderColor: Hibizcus.colorArray[1], fillColor: .clear)
                
                // Draw the glyph name if the flag is set & name exists
                if item.gn != nil && viewOptions.showGlyphNames {
                    var gn = item.gn!
                    gn = gn.count >= 10 ? gn.truncated(limit: 10) : gn
                    drawGlyphName(inContext: context, glyphName: gn, x: x+cellWidth/2, y: 3, color: NSColor.textColor.withAlphaComponent(0.6).cgColor, pointSize: glyphNamePointSize)
                }
            }
            x += cellWidth
        }
    }
    
    func drawMetricsLines(context:CGContext, xStart:CGFloat, cellWidth:CGFloat, baseLine:CGFloat, xHeight:CGFloat) {
        drawLine(inContext: context, fromPoint: CGPoint(x: xStart, y: xHeight), toPoint: CGPoint(x: xStart+cellWidth, y: xHeight), lineWidth: 1, lineColor: metricLineColor)
        drawLine(inContext: context, fromPoint: CGPoint(x: xStart, y: baseLine), toPoint: CGPoint(x: xStart+cellWidth, y: baseLine), lineWidth: 1, lineColor: metricLineColor)
    }
    
    func drawSystemLog(context:CGContext, cellWidth:CGFloat, baseLine:CGFloat) {
        var unichars = [unichar]()
        var clusters = [Int]()
        
        for item in tvLogItem!.items {
            if item.u != nil {
                unichars.append(UniChar(item.u!))
                clusters.append(item.cl!)
            }
        }
        
        var x:CGFloat = 0
        for unichar in unichars {
            let s = String(UnicodeScalar(unichar)!)
            let xp = x + (cellWidth/2)
            drawGlyphName(inContext: context, glyphName: s, x: xp, y: baseLine, color: NSColor.white.withAlphaComponent(0.6).cgColor, pointSize: 40)
            
            if viewOptions.showGlyphNames {
                let gn = "U+" + s.hexString()
                drawGlyphName(inContext: context, glyphName: gn, x: x+cellWidth/2, y: 3, color: NSColor.textColor.withAlphaComponent(0.6).cgColor, pointSize: glyphNamePointSize)
            }

            // Draw vertical like at the end of the cell
            drawLine(inContext: context, fromPoint: CGPoint(x: x+cellWidth, y: 0), toPoint: CGPoint(x: x+cellWidth, y: self.bounds.height), lineWidth: 1, lineColor: frameColor)

            x += cellWidth
        }
    }
    
    func getMaxGlyphWidth() -> CGFloat {
        var w:Float = 60 // default
        
        for item in tvLogItem!.items {
            if item.w != nil {
                w = max(w, item.w!)
            }
        }
        
        return CGFloat(w * 1.2)
    }
    
    func computeBaseLine() -> CGFloat {
        let font = ctFont! as NSFont
        // Bounding boxes of the font
        let boundingRect    = font.boundingRectForFont
        // Height of the view and the padding requied
        // to place the glyphs in the middle
        let viewHeight      = self.bounds.height
        let fontHeight      = boundingRect.height
        let yPadding        = viewHeight>fontHeight ? (viewHeight-boundingRect.height)/2 : 0
        // Set the offset
        var yOffset = yPadding + (0-boundingRect.origin.y)
        // Consider the height of the glyph name label, if set
        if viewOptions.showGlyphNames {
            yOffset += getGlyphNameHeight(glyphName: "GlyphName", pointSize: glyphNamePointSize)
        }
        return yOffset
    }
    
    func drawGlyphName(inContext:CGContext, glyphName:String, x:CGFloat, y:CGFloat, color:CGColor, pointSize:CGFloat) {
        // Label attributes
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let attributes: [NSAttributedString.Key : Any] = [
            .paragraphStyle: paragraphStyle,
            .font: NSFont.systemFont(ofSize: pointSize), //   NSFont.init(name: "Monaco", size: 10)!,
            .foregroundColor: NSColor.init(cgColor:color)!
        ]
        
        let labelSize = glyphName.size(withAttributes: attributes)
        let xp = x - (labelSize.width/2)
        
        // Daww the label
        glyphName.draw(at: CGPoint(x: xp, y: y), withAttributes: attributes)
        
        // there is no promise that the text matrix will be identity before calling the next draw
        // see this post: https://stackoverflow.com/questions/53047093/swift-text-draw-method-messes-up-cgcontext
        inContext.textMatrix = .identity
    }
    
    func getGlyphNameHeight(glyphName:String, pointSize:CGFloat) -> CGFloat {
        // Label attributes
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let attributes: [NSAttributedString.Key : Any] = [
            .paragraphStyle: paragraphStyle,
            .font: NSFont.systemFont(ofSize: pointSize), //NSFont.init(name: "Monaco", size: 10)!,
        ]
        
        let labelSize = glyphName.size(withAttributes: attributes)
        
        return labelSize.height
    }
}
