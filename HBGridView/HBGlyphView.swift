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

    @Binding var document: HibizcusDocument
    @EnvironmentObject var hbProject: HBProject
    @ObservedObject var gridViewOptions: HBGridViewOptions
    
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
                            //Image(systemName: "doc.on.doc")
                            Text("Copy text")
                                .font(.callout)
                        })
                        .font(.system(size: 20))
                        .padding(.top, 10)
                        .padding(.bottom, 0)
                        .padding(.horizontal, 10)
                        .buttonStyle(PlainButtonStyle())
                        .help("Copy \(gridItems[currItem].text!) to clipboard")
                        
                        // Open in String Viewer
                        Button(action: {
                            //openTextInStringViewer(text: gridItems[currItem].text!)
                            if let url = URL(string: "Hibizcus://stringview?\(urlParamsForToolWindow(text: gridItems[currItem].text ?? ""))") {
                                openURL(url)
                            }
                        }, label: {
                            //Image(systemName: "rectangle.and.text.magnifyingglass")
                            Text("String viewer")
                                .font(.callout)
                        })
                        .font(.system(size: 20))
                        .padding(.top, 10)
                        .padding(.bottom, 0)
                        .padding(.horizontal, 10)
                        .buttonStyle(PlainButtonStyle())
                        .help("Open \(gridItems[currItem].text!) in StringViewer")
                        
                        // Open in Trace Viewer, only if there is file access
                        Button(action: {
                            //openTextInStringViewer(text: gridItems[currItem].text!)
                            if let url = URL(string: "Hibizcus://traceview?\(urlParamsForToolWindow(text: gridItems[currItem].text ?? ""))") {
                                openURL(url)
                            }
                        }, label: {
                            //Image(systemName: "rectangle.and.text.magnifyingglass")
                            Text("Trace viewer")
                                .font(.callout)
                        })
                        .font(.system(size: 20))
                        .padding(.top, 10)
                        .padding(.bottom, 0)
                        .padding(.horizontal, 10)
                        .buttonStyle(PlainButtonStyle())
                        .help("Open \(gridItems[currItem].text!) in TraceViewer")
                        .disabled(hbProject.hbFont1.fileUrl == nil)
                    }
                    else if gridItems[currItem].type == HBGridItemItemType.Glyph {
                        Text("Glyph ID: \(gridItems[currItem].glyphIds[0])")
                            .padding(.trailing, 10)
                            .padding(.top, 20)
                    }
                    else {
                        Text(" ")
                    }
                }
            }
            Divider()

            VStack {
                HBGridCellViewRepresentable(gridItem: gridItems[currItem], gridViewOptions: gridViewOptions, scale: scale)
                    .frame(width: max((gridItems[currItem].width[0] * scale * 1.2), 800), height: 600, alignment: .center)
                
                Divider()
                
                if gridItems[currItem].hasDiff(excludeOutlines: gridViewOptions.dontCompareOutlines) && hbProject.hbFont2.available { //fileUrl != nil {
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
    
    // Help construct URL parameters
    func urlParamsForToolWindow(text: String) -> String {
        let etext = text.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        var f1Url = ""
        var f2Url = ""
        var bkMk1 = ""
        var bkMk2 = ""
        // Script info for system fonts in project
        var scrp1 = ""
        var chrs1 = ""
        var scrp2 = ""
        var chrs2 = ""
        
        if document.projectData.fontFile1Bookmark != nil {
            bkMk1 = document.projectData.fontFile1Bookmark!.base64EncodedString()
        } else if hbProject.hbFont1.fileUrl != nil {
            f1Url = hbProject.hbFont1.fileUrl?.absoluteString ?? ""
        } else {
            scrp1 = hbProject.hbFont1.selectedScript
            chrs1 = hbProject.hbFont1.charsInScript
        }
        
        if document.projectData.fontFile2Bookmark != nil {
            bkMk2 = document.projectData.fontFile2Bookmark!.base64EncodedString()
        } else if hbProject.hbFont2.fileUrl != nil {
            f2Url = hbProject.hbFont2.fileUrl?.absoluteString ?? ""
        } else {
            scrp2 = hbProject.hbFont2.selectedScript
            chrs2 = hbProject.hbFont2.charsInScript
        }

        // Project name is the last path component of the project file
        let prjName = hbProject.projectName
        
        let echrs1 = chrs1.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let echrs2 = chrs2.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        return "text=\(etext)&font1BookMark=\(bkMk1)&font2BookMark=\(bkMk2)&font1Url=\(f1Url)&font2Url=\(f2Url)&project=\(prjName)" +
            "&font1Script=\(scrp1)&font2Script=\(scrp2)&font1Chars=\(echrs1)&font2Chars=\(echrs2)"

    }
}

