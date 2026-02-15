//
//  HBStringLayoutView.swift
//  LayoutView
//
//  Created by Muthu Nedumaran on 2020/09/05
//  Modified by Muthu Nedumaran on 2021/03/25
//  Copyright © 2020 Murasu Systems Sdn bhd. All rights reserved.
//

#if os(iOS) || os(watchOS)
    import UIKit
    public typealias HBView=UIView
#elseif os(OSX)
    import Cocoa
    public typealias HBView=NSView
#endif

//import Cocoa
import Combine
import SwiftUI

enum LabelPosition { case left; case right }

class HBStringLayoutView: HBView /*NSView*/ {
    // This can be in preferences, later
    let metricsColor_01 = Hibizcus.FontColor.MainFontColor
    let metricsColor_02 = Hibizcus.FontColor.CompareFontColor
    
    var hbFont1: HBFont = HBFont(filePath: "", fontSize: 40)
    
    var hbFont2: HBFont = HBFont(filePath: "", fontSize: 40)
    
    var slData1 = StringLayoutData()
    var slData2 = StringLayoutData()
    
    var viewSettings: HBStringViewSettings = HBStringViewSettings() {
        didSet {
            needsDisplay = true
        }
    }
    
    var text: String = "" {
        didSet {
            needsDisplay = true
        }
    }
    
    var fontSize: Double = 40 {
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
                
        // Drawing code here.
        NSColor.textBackgroundColor.setFill()
        bounds.fill()
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Calculate a shared baseline position based on the first font
        var sharedYOffset: CGFloat = 0
        
        if hbFont1.available && viewSettings.showFont1 {
            // --- Draw a diagonal line across the height of the font - for debugging
            /*
            let f = slData.font! as NSFont
            let b = f.boundingRectForFont
            drawLine(inContext: context, fromPoint: CGPoint(x: b.origin.x + (0-b.origin.x), y: b.origin.y + (0-b.origin.y)), toPoint: CGPoint(x: b.width, y: b.height + (0-b.origin.y)), lineWidth: 2.0, lineColor: .white)
            */
            
            var ctFont1 = hbFont1.ctFont!
            if CTFontGetSize(ctFont1) != CGFloat(fontSize) {
                ctFont1 = CTFontCreateCopyWithAttributes(ctFont1, CGFloat(fontSize), nil, nil)
            }
            
            // Use font1's baseline as the reference
            sharedYOffset = getYOffsetFor(font: ctFont1 as NSFont)
            
            if ( viewSettings.drawMetrics && text.count > 0 ) {
                drawMetricsWithData(ctFont: ctFont1, context: context, lineColor:metricsColor_01, labelPosition: .left, drawUnderline: viewSettings.drawUnderLine, yOffset: sharedYOffset)
            }
            drawGlyphsWithData(slData: slData1, ctFont: ctFont1, isMain: true, context: context, yOffset: sharedYOffset)
        }
        else {
            print("Font 1 not set \(hbFont1)")
        }
        
        if hbFont2.available && viewSettings.showFont2 {
            
            var ctFont2 = hbFont2.ctFont!
            if CTFontGetSize(ctFont2) != CGFloat(fontSize) {
                ctFont2 = CTFontCreateCopyWithAttributes(ctFont2, CGFloat(fontSize), nil, nil)
            }
            
            // Use the same yOffset as font1 (shared baseline)
            if ( viewSettings.drawMetrics && text.count > 0  ) {
                drawMetricsWithData(ctFont: ctFont2, context: context, lineColor:metricsColor_02, labelPosition: .right, drawUnderline: viewSettings.drawUnderLine, yOffset: sharedYOffset)
            }
            drawGlyphsWithData(slData: slData2, ctFont: ctFont2, isMain: false, context: context, yOffset: sharedYOffset)
        }
    }

    func drawMetricsWithData(ctFont: CTFont, context: CGContext, lineColor:CGColor, labelPosition: LabelPosition, drawUnderline: Bool, yOffset: CGFloat) {
        let nsFont  = ctFont as NSFont
        // Use the passed yOffset instead of calculating it
        
        // Baseline
        drawMetricLine(atY: yOffset, inContext: context, label:"base", lx:labelPosition, ly:1, color: lineColor)
        
        // Ascender
        drawMetricLine(atY: yOffset+nsFont.ascender, inContext: context, label:"asc", lx:labelPosition, ly:1, color: lineColor)
        
        // Descender
        drawMetricLine(atY: yOffset+nsFont.descender, inContext: context, label:"dec", lx:labelPosition, ly:0, color: lineColor)

        // xHeight
        drawMetricLine(atY: yOffset+nsFont.xHeight, inContext: context, label:"x", lx:labelPosition, ly:1, color: lineColor)
        
        // CapHeight
        drawMetricLine(atY: yOffset+nsFont.capHeight, inContext: context, label:"cap", lx:labelPosition, ly:1, color: lineColor)

        // Underline
        if drawUnderline {
            drawMetricLine(atY: yOffset+nsFont.underlinePosition, inContext: context, label:"ul", lx:labelPosition, ly:0, color: lineColor)
        }
    }
    
    func drawGlyphsWithData(slData: StringLayoutData, ctFont: CTFont, isMain: Bool, context: CGContext?, yOffset: CGFloat) {
        // Use the passed yOffset instead of calculating it
        var xOffset = CGFloat(30) // For some padding
        
        // Values in sdData were obtained with a point size of 40
        let scale = CGFloat(fontSize/40)
        
        // Adjust starting position if writing direction is RTL
        if text.isWrittenRightToLeft() {
            xOffset = bounds.size.width - ((slData.width*scale) + 30)
        }
        
        for glyphIndex in 0..<slData.hbGlyphs.count {
                        
            var fillColor = slData.hbGlyphs[glyphIndex].color.cgColor
            // Use single colors if string needs to be shown in both fonts
            if hbFont1.available && hbFont2.available && viewSettings.showFont1 && viewSettings.showFont2 {
                fillColor = isMain ? Hibizcus.FontColor.MainFontColor : Hibizcus.FontColor.CompareFontColor
            }
            context!.setFillColor(fillColor!)
            
            var g = [CGGlyph]()
            g.append(slData.hbGlyphs[glyphIndex].glyphId)
            var p = [CGPoint]()
            var pos = slData.positions[glyphIndex]
            // 2026-02-15: By zeroing out the Y positioning, we're losing the anchor-specific
            // vertical positioning that CoreText/HarfBuzz calculated.
            //pos = CGPoint(x: (pos.x * scale)+xOffset, y: yOffset) // Zero out relative Y positioning
            pos = CGPoint(x: (pos.x * scale)+xOffset, y: (pos.y * scale) + yOffset)
            
            p.append(pos)
            CTFontDrawGlyphs(ctFont, g, p, 1, context!)
            
            // Draw the bounding box
            if viewSettings.drawBoundingBox {
                var ctGlyph = slData.hbGlyphs[glyphIndex].glyphId
                let boundingBox = withUnsafePointer(to: &ctGlyph) { pointer -> CGRect in
                    return CTFontGetBoundingRectsForGlyphs(ctFont, .default, pointer, nil, 1)
                }
                let bbx = CGRect(x: boundingBox.minX + pos.x, y: boundingBox.minY + pos.y, width: boundingBox.width, height: boundingBox.height)
                drawRoundedRect(rect: bbx, inContext: context, radius: 0.1, borderColor: fillColor!/*slData.hbGlyphs[glyphIndex].color.cgColor!*/, fillColor: CGColor.clear)
            }
            
            // Draw the anchor points
            //print("Draw anchors? \(viewSettings.drawAnchors), anchors count: \(slData.anchors.count)")
            if viewSettings.drawAnchors && slData.anchors.count > 0 {
                let anchors = slData.anchors[glyphIndex]
                for anchor in anchors {
                    let ax = (anchor.x * scale) + pos.x
                    let ay = (anchor.y * scale) + yOffset
                    drawLine(inContext: context!, fromPoint: CGPoint(x:ax-5,y: ay), toPoint: CGPoint(x:ax+5,y: ay), lineWidth: 1, lineColor: Hibizcus.AnchorColor)
                    drawLine(inContext: context!, fromPoint: CGPoint(x:ax, y: ay-5), toPoint: CGPoint(x:ax,y: ay+5), lineWidth: 1, lineColor: Hibizcus.AnchorColor)
                }
            }
        }
    }
    
    func getYOffsetFor(font:NSFont) -> CGFloat {
        // Bounding boxes of the font
        let boundingRect    = font.boundingRectForFont
        // Height of the view and the padding requied
        // to place the glyphs in the middle
        let viewHeight      = self.bounds.height
        let fontHeight      = boundingRect.height
        let yPadding        = viewHeight>fontHeight ? (viewHeight-boundingRect.height)/2 : 0
        // Set the offset
        let yOffset = yPadding + (0-boundingRect.origin.y)
        return yOffset
    }
}

