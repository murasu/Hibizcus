//
//  HBSidebarFont.swift
//
//  Created by Muthu Nedumaran on 15/4/21.
//

import Combine
import SwiftUI
import AppKit

struct HBSidebarFont: View {    
    @EnvironmentObject var hbProject: HBProject
    @State private var showingScriptSelection = false
    var showCompareFont = true

    var body: some View {
        HStack (alignment: .top) {
            
            // ----------------------------------------
            // First Font File
            // ----------------------------------------

            if hbProject.hbFont1.fileUrl != nil {
                Button(action: removeFont1, label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                })
                .padding(.leading, 10)
                .accentColor(.red)
                .help("Remove font")
            }
            else {
                Button(action: addFont1, label: {
                    Image(systemName: "plus.circle")
                })
                .padding(.leading, 10)
                .help("Set main font")
            }
            Text("Main font:")
                .multilineTextAlignment(.leading)
                .padding(.trailing, 15)
                .padding(.bottom, 2)
            Spacer()
            if hbProject.hbFont1.fileWatcher.fontFileChanged { 
                Button(action: reloadFont1, label: {
                    Image(systemName: "arrow.clockwise")
                })
                .padding(.trailing, 15)
                .help("Reload font")
            }
            if hbProject.hbFont1.fileUrl == nil {
                Button(action: selectScriptForSystemFont, label: {
                    Image(systemName: "globe")
                })
                .padding(.trailing, 15)
                .help("Select script for system font")
                .sheet(isPresented: $showingScriptSelection, onDismiss: scriptSelected) {
                    HBFontScriptSelectionView(hbFont: hbProject.hbFont1)
                }
            }
        }
        if hbProject.hbFont1.fileUrl != nil {
            Text(hbProject.hbFont1.fileUrl!.lastPathComponent)
                .multilineTextAlignment(.leading)
                .padding(.leading, 20)
                .padding(.bottom, 2)
                .foregroundColor(Hibizcus.FontColor.MainFontUIColor)
            Text(hbProject.hbFont1.version)
                .multilineTextAlignment(.leading)
                .padding(.leading, 20)
                .padding(.bottom, 10)
                .foregroundColor(Hibizcus.FontColor.MainFontUIColor)
            
            // TODO: Should I have a seperate flag to show shaper?
            if showCompareFont {
                Text("Shaper:")
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 20)
                    .padding(.bottom, 5)
                
                Picker("", selection: $hbProject.hbFont1.selectedShaper) {
                    ForEach(hbProject.hbFont1.shapers, id: \.self) { scriptName in
                        Text(scriptName)
                    }
                }
                .padding(.leading, 10)
                .padding(.trailing,15)
                .padding(.bottom, 30)
            }
        }
        else {
            Text("None selected")
                .multilineTextAlignment(.leading)
                .padding(.leading, 20)
                .padding(.bottom, 20)
                .foregroundColor(.gray)
        }
        
        // ----------------------------------------
        // Second Font File
        // ----------------------------------------
        
        if showCompareFont {
            Divider()
            
            HStack (alignment: .top) {
                if hbProject.hbFont2.fileUrl != nil {
                    Button(action: removeFont2, label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    })
                    .padding(.leading, 10)
                    .accentColor(.red)
                    .help("Remove font")
                }
                else {
                    Button(action: addFont2, label: {
                        Image(systemName: "plus.circle")
                    })
                    .padding(.leading, 10)
                    .help("Set comparison font")
                }
                Text("Comparison font:")
                    .multilineTextAlignment(.leading)
                    .padding(.trailing, 15)
                    .padding(.bottom, 2)
                Spacer()
                if hbProject.hbFont2.fileWatcher.fontFileChanged {
                    Button(action: reloadFont2, label: {
                        Image(systemName: "arrow.clockwise")
                    })
                    .padding(.trailing, 15)
                    .help("Reload font")
                }
                if hbProject.hbFont2.fileUrl == nil {
                    Button(action: selectScriptForSystemFont, label: {
                        Image(systemName: "globe")
                    })
                    .padding(.trailing, 15)
                    .help("Select script for system font")
                }
            }
            .padding(.top, 15)
            
            
            if hbProject.hbFont2.fileUrl != nil {
                Text(hbProject.hbFont2.fileUrl!.lastPathComponent)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 20)
                    .padding(.bottom, 2)
                    .foregroundColor(Hibizcus.FontColor.CompareFontUIColor)
                Text(hbProject.hbFont2.version)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 20)
                    .padding(.bottom, 10)
                    .foregroundColor(Hibizcus.FontColor.CompareFontUIColor)
                Text("Shaper:")
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 20)
                    .padding(.bottom, 5)
                
                Picker("", selection: $hbProject.hbFont2.selectedShaper) {
                    ForEach(hbProject.hbFont2.shapers, id: \.self) { scriptName in
                        Text(scriptName)
                    }
                }
                .padding(.leading, 10)
                .padding(.trailing,15)
                .padding(.bottom, 30)
            }
            else {
                Text("None selected")
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 20)
                    .padding(.bottom, 20)
                    .foregroundColor(.gray)
            }
        }
    }
    
    func addFont1() {
        openFont(fontNum:1)
    }
    
    func addFont2() {
        openFont(fontNum:2)
    }
    
    func openFont(fontNum:Int) {
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Select file"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["ttf","ttc","otf"]
        openPanel.begin { (result) -> Void in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                let selectedPath = openPanel.url!.path
                DispatchQueue.main.async {
                    print("Selected \(selectedPath) for font \(fontNum)")
                    switch (fontNum) {
                    case 1:
                        hbProject.hbFont1.setFontFile(filePath: selectedPath)
                        hbProject.refresh()
                    case 2:
                        hbProject.hbFont2.setFontFile(filePath: selectedPath)
                        hbProject.refresh()
                    default:
                        print("This should never be printed!")
                    }
                    
                }
            }
        }
    }
    
    func removeFont1() {
        // Remove the bookmark if this font in the document
        //document.projectData.fontFile1Bookmark = nil
        // Update hbFont
        hbProject.hbFont1.setFontFile(filePath: "")
        hbProject.refresh()
    }
    
    func removeFont2() {
        // Remove the bookmark if this font in the document
        //document.projectData.fontFile2Bookmark = nil
        // Update hbFont
        hbProject.hbFont2.setFontFile(filePath: "")
        hbProject.refresh()
    }
    
    func reloadFont1() {
        hbProject.hbFont1.fileWatcher.fontFileChanged = false
        hbProject.hbFont1.reloadFont()
        hbProject.refresh()
    }
    
    func reloadFont2() {
        hbProject.hbFont2.fileWatcher.fontFileChanged = false
        hbProject.hbFont2.reloadFont()
        hbProject.refresh()
    }
    
    func selectScriptForSystemFont() {        
        showingScriptSelection = true
    }
    
    func scriptSelected() {
        showingScriptSelection = false
    }
}
