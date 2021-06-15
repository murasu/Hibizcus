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
    
    @State var currItem         = 0
    @State var scale:CGFloat    = 0
    var tappedItem: HBGridItem
    var gridItems: [HBGridItem]

    var body: some View {
        VStack {
            ZStack {
                Text((gridItems[currItem].type == HBGridItemItemType.Glyph ? glyphItemLabel() : gridItems[currItem].text) ?? "")
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
                    if gridItems[currItem].type != HBGridItemItemType.Glyph && gridItems[currItem].text != nil {
                        Button(action: { copyTextToClipboard(textToCopy: gridItems[currItem].text!) }, label: {
                            Image(systemName: "doc.on.doc")
                        })
                        .font(.system(size: 20))
                        .padding(.top, 10)
                        .padding(.bottom, 0)
                        .padding(.horizontal, 10)
                        .buttonStyle(PlainButtonStyle())
                        .help("Copy \(gridItems[currItem].text!) to clipboard")
                        
                        // Open in String Viewer
                        Button(action: { openTextInStringViewer(text: gridItems[currItem].text!) }, label: {
                            Image(systemName: "rectangle.and.text.magnifyingglass")
                        })
                        .font(.system(size: 20))
                        .padding(.top, 10)
                        .padding(.bottom, 0)
                        .padding(.horizontal, 10)
                        .buttonStyle(PlainButtonStyle())
                        .help("Open \(gridItems[currItem].text!) in StringViewer")
                    }
                    else {
                        Text(" ")
                    }
                }
            }
            Divider()
            
            VStack {
                HBGridCellViewRepresentable(wordItem: gridItems[currItem], scale: scale) //, viewOptions: viewOptions)
                    .frame(width: max((gridItems[currItem].width[0] * scale * 1.2), 800), height: 600, alignment: .center)
                
                Divider()
                
                if gridItems[currItem].hasDiff() && hbProject.hbFont2.fileUrl != nil {
                    HStack {
                        if gridItems[currItem].diffWidth {
                            Text(" Width Mismatch ")
                                .font(.system(size: 12))
                            if gridItems[currItem].diffGlyf || gridItems[currItem].diffLayout {
                                Divider()
                            }
                        }
                        if gridItems[currItem].diffGlyf {
                            Text(" Glyf Mismatch ")
                                .font(.system(size: 12))
                            if gridItems[currItem].diffLayout {
                                Divider()
                            }
                        }
                        if gridItems[currItem].diffLayout {
                            Text(" Layout Mismatch ")
                                .font(.system(size: 12))
                        }
                    }
                    Divider()
                }
                HStack {
                    Button("Prev") {
                        if currItem > 0 {
                            currItem  -= 1
                        }
                    }
                    Spacer()
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    Spacer()
                    Button("Next") {
                        if currItem < gridItems.count-1 {
                            currItem  += 1
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 5)//-25)
            .padding(.bottom, 20)
        }
        .onAppear() {
            currItem    = gridItems.firstIndex(of: tappedItem) ?? 0
            scale       = tappedItem.type == .Word ? 4.0 : 6.0
        }
    }
    
    func glyphItemLabel() -> String {
        if gridItems[currItem].uniLabel.count > 0 {
            return "\(gridItems[currItem].label) - \(gridItems[currItem].uniLabel)"
        }
        
        return gridItems[currItem].label
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

