//
//  HBGridCellView.swift
//
//  Created by Muthu Nedumaran on 3/3/21.
//

import Cocoa
import Combine
import SwiftUI

class HBGridCellView: NSView {
    let glyphNamePointSize:CGFloat = 10
    let frameColor = NSColor.textColor.withAlphaComponent(0.1).cgColor
    let metricLineColor = NSColor.textColor.withAlphaComponent(0.15).cgColor
    
    // The word string that's in the cell
    var gridItem: HBGridItem? {
        didSet{
            needsDisplay = true
        }
    }
        
    var hbFont1: HBFont? {
        didSet{
            needsDisplay = true
        }
    }
    
    var hbFont2: HBFont? {
        didSet{
            needsDisplay = true
        }
    }
    
    var gridViewOptions: HBGridViewOptions = HBGridViewOptions() {
        didSet {
            needsDisplay = true
        }
    }
    
    var scale: CGFloat = 1 {
        didSet {
            needsDisplay = true
        }
    }
    
    // 2022-07-13
    var showMainFont: Bool = true  {
        didSet {
            needsDisplay = true
        }
    }
    
    var showCompareFont: Bool = true {
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
        
        if hbFont1 == nil || gridItem == nil {
            return
        }
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
                
        var ctFont1 = hbFont1!.ctFont!
        var ctFont2 = hbFont2!.ctFont!
        
        if scale != 1.0 {
            let newSize = scale * CTFontGetSize(ctFont1)
            ctFont1 = CTFontCreateCopyWithAttributes(ctFont1, newSize, nil, nil)
            ctFont2 = CTFontCreateCopyWithAttributes(ctFont2, newSize, nil, nil)
        }
        
        let baseLine: CGFloat   = computeBaseLine(ctFont: ctFont1)
        let xHeight: CGFloat    = baseLine + CTFontGetXHeight(ctFont1)
        
        let showDiff    = gridItem!.hasDiff(excludeOutlines: gridViewOptions.dontCompareOutlines) && hbFont2!.available && (showMainFont && showCompareFont)
        let borderColor = showDiff ? NSColor.systemRed.cgColor : NSColor.textColor.withAlphaComponent(0.2).cgColor
        let borderWidth = showDiff ? 2 : 1
        if scale > 1.0 {
            //print("Drawing metrics lines for grid item \(gridItem!)")
            // If the scale is > 1, draw all metrices along w their labels
            drawMetricLinesForFont(forFont: ctFont1, inContext: context, baseLine: baseLine, lineColor: metricLineColor, labelXPos: .left, drawUnderlinePos: false) 
        }
        else {
            // Otherwise, just the baseline and xheight
            drawRoundedRect(rect: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height), inContext: context, radius: 0, borderColor: borderColor, fillColor: .clear, strokeWidth: CGFloat(borderWidth))
            drawMetricsLines(context: context, xStart: 0, cellWidth: self.bounds.width, baseLine: baseLine, xHeight: xHeight)
            // Draw the glyph name
            let glyphName = gridItem!.label.truncated(limit: 15)
            drawGlyphName(inContext: context, glyphName: glyphName, x: self.bounds.width/2, y: 3, color: NSColor.textColor.withAlphaComponent(0.6).cgColor, pointSize: glyphNamePointSize)
        }
        
        // Set the colors
        var textColors:[CGColor] = [NSColor.textColor.withAlphaComponent(0.7).cgColor]
        
        var theFonts:[CTFont] = [ctFont1]
        var theLayoutData:[StringLayoutData?] = [hbFont1?.getStringLayoutData(forText: gridItem?.text ?? "")]
        if hbFont2 != nil && hbFont2!.available {
            textColors  = [Hibizcus.FontColor.MainFontColor, Hibizcus.FontColor.CompareFontColor]
            theFonts.append(ctFont2)
            theLayoutData.append(hbFont2?.getStringLayoutData(forText: gridItem?.text ?? ""))
        }
        
        var colorIndex = 0
        var layoutDatum:StringLayoutData?
        // 2022-07-13 : Show glyphs in color by default if either font is turned off
        let showColoredGlyphs = (gridItem!.type != HBGridItemItemType.Glyph) && (showMainFont != showCompareFont) ? true : gridItem!.colorGlyphs
        
        for theFont in theFonts {
            // 2022-07-13 : only show selected font
            if colorIndex == 0 && !showMainFont {
                colorIndex += 1
                continue
            }
            if colorIndex == 1 && !showCompareFont {
                continue
            }
                        
            if gridItem!.type == HBGridItemItemType.Glyph {
                layoutDatum = nil
                let gid = gridItem!.glyphIds[colorIndex]
                if gid != kCGFontIndexInvalid {
                    layoutDatum = StringLayoutData()
                    layoutDatum!.count = 1
                    layoutDatum!.width = CGFloat(gridItem!.width[colorIndex] * scale)
                    layoutDatum!.hbGlyphs = [HBGlyph(glyphId:gid)]
                    layoutDatum!.positions = [CGPoint(x: 0,y: 0)]
                }
            }
            else {
                layoutDatum = theLayoutData[colorIndex]
                layoutDatum!.width *= scale
            }
            
            if layoutDatum != nil {
                let layoutWidth = layoutDatum!.width
                let leftPadding:CGFloat = (self.bounds.width - layoutWidth) / 2
                for i in 0 ..< layoutDatum!.count {
                    context.setFillColor(textColors[colorIndex])
                    if showColoredGlyphs /*gridItem!.colorGlyphs*/ {
                        context.setFillColor(layoutDatum!.hbGlyphs[i].color.cgColor!)
                    }
                    let glyphs = [CGGlyph(layoutDatum!.hbGlyphs[i].glyphId)]
                    var pos = layoutDatum!.positions[i]
                    if scale > 1.0 {
                        pos = CGPoint(x: pos.x*scale, y: pos.y*scale)
                    }
                    CTFontDrawGlyphs(theFont, glyphs, [CGPoint(x: leftPadding + pos.x, y: pos.y+baseLine)], 1, context)
                }
                
                // Draw the left and right boundaries
                let xLeft:CGFloat = (self.bounds.width - layoutWidth) / 2
                let xRight:CGFloat = xLeft + layoutWidth
                let y1 = scale > 1.0 ? 0 : baseLine-10
                let y2 = scale > 1.0 ? self.bounds.height : xHeight+10
                let sbColor = showDiff ? textColors[colorIndex] : metricLineColor
                drawLine(inContext: context, fromPoint: CGPoint(x: xLeft, y: y1), toPoint: CGPoint(x: xLeft, y: y2), lineWidth: 1, lineColor: sbColor)
                drawLine(inContext: context, fromPoint: CGPoint(x: xRight, y: y1), toPoint: CGPoint(x: xRight, y: y2), lineWidth: 1, lineColor: sbColor)
            }
            colorIndex += 1
        }
    }
    
    func drawMetricsLines(context:CGContext, xStart:CGFloat, cellWidth:CGFloat, baseLine:CGFloat, xHeight:CGFloat) {
        drawLine(inContext: context, fromPoint: CGPoint(x: xStart, y: xHeight), toPoint: CGPoint(x: xStart+cellWidth, y: xHeight), lineWidth: 1, lineColor: metricLineColor)
        drawLine(inContext: context, fromPoint: CGPoint(x: xStart, y: baseLine), toPoint: CGPoint(x: xStart+cellWidth, y: baseLine), lineWidth: 1, lineColor: metricLineColor)
    }
    
    func computeBaseLine(ctFont: CTFont) -> CGFloat {
        let font = ctFont as NSFont
        // Bounding boxes of the font
        let boundingRect    = font.boundingRectForFont
        // Height of the view and the padding requied
        // to place the glyphs in the middle
        let viewHeight      = self.bounds.height
        let fontHeight      = boundingRect.height
        let yPadding        = viewHeight>fontHeight ? (viewHeight-boundingRect.height)/2 : 0
        // Set the baseline
        return yPadding + (0-boundingRect.origin.y)
    }
    
    //TODO: This is also available in TraceView. Find a way to make it universal
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
        
        // Draw the label
        glyphName.draw(at: CGPoint(x: xp, y: y), withAttributes: attributes)
        
        // there is no promise that the text matrix will be identity before calling the next draw
        // see this post: https://stackoverflow.com/questions/53047093/swift-text-draw-method-messes-up-cgcontext
        inContext.textMatrix = .identity
    }
}

