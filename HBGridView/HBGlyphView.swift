//
//  HBGlyphView.swift
//
//  Created by Muthu Nedumaran on 8/3/21.
//

import Cocoa
import Combine
import SwiftUI

struct HBGlyphView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var hbProject: HBProject

    let scale: CGFloat
    let gridItem: HBGridItem
    let viewOptions: HBGridViewOptions
    
    var body: some View {
        VStack {
            ZStack {
                Text((gridItem.type == HBGridItemItemType.Glyph ? glyphItemLabel() : gridItem.text) ?? "")
                    .font(.title)
                    .padding(.horizontal, 15)
                    .padding(.top, 15)
                    .padding(.bottom, 10)
                
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }, label: {
                        Image(systemName: "multiply.circle")
                    })
                    .font(.system(size: 20))
                    .padding(.top, 10)
                    .padding(.bottom, 0)
                    .padding(.horizontal, 10)
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    // Copy button - only for clusters and words.
                    // TODO: Glyphs only if there's a unicode value
                    if gridItem.type != HBGridItemItemType.Glyph && gridItem.text != nil {
                        Button(action: { copyTextToClipboard(textToCopy: gridItem.text!) }, label: {
                            Image(systemName: "doc.on.doc")
                        })
                        .font(.system(size: 20))
                        .padding(.top, 10)
                        .padding(.bottom, 0)
                        .padding(.horizontal, 10)
                        .buttonStyle(PlainButtonStyle())
                        .help("Copy \(gridItem.text!) to clipboard")
                        
                        // Open in String Viewer
                        Button(action: { openTextInStringViewer(text: gridItem.text!) }, label: {
                            Image(systemName: "rectangle.and.text.magnifyingglass")
                        })
                        .font(.system(size: 20))
                        .padding(.top, 10)
                        .padding(.bottom, 0)
                        .padding(.horizontal, 10)
                        .buttonStyle(PlainButtonStyle())
                        .help("Open \(gridItem.text!) in StringViewer")
                    }
                    else {
                        Text(" ")
                    }
                }
            }
            Divider()
            
            VStack {
                HBGridCellViewRepresentable(wordItem: gridItem, scale: scale, viewOptions: viewOptions)
                    .frame(width: max((gridItem.width[0] * scale * 1.2), 800), height: 600, alignment: .center)
                
                Divider()
                
                if gridItem.hasDiff() && hbProject.hbFont2.fileUrl != nil {
                    HStack {
                        if gridItem.diffWidth {
                            Text(" Width Mismatch ")
                                .font(.system(size: 12))
                            if gridItem.diffGlyf || gridItem.diffLayout {
                                Divider()
                            }
                        }
                        if gridItem.diffGlyf {
                            Text(" Glyf Mismatch ")
                                .font(.system(size: 12))
                            if gridItem.diffLayout {
                                Divider()
                            }
                        }
                        if gridItem.diffLayout {
                            Text(" Layout Mismatch ")
                                .font(.system(size: 12))
                        }
                    }
                    Divider()
                }
                
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 5)//-25)
            .padding(.bottom, 20)
        }
    }
    
    func glyphItemLabel() -> String {
        if gridItem.uniLabel.count > 0 {
            return "\(gridItem.label) - \(gridItem.uniLabel)"
        }
        
        return gridItem.label
    }
    
    func openTextInStringViewer(text: String) {
        if let url = URL(string: "Hibizcus://stringview") {
            // Open the StringViewer
            hbProject.hbStringViewText = text
            openURL(url)
            // Close the view 
            presentationMode.wrappedValue.dismiss()
        }
    }
}

