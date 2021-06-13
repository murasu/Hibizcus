//
//  HBStringView.swift
//
//  Created by Muthu Nedumaran on 25/3/21.
//

import Combine
import SwiftUI
import AppKit

class HBStringViewSettings: ObservableObject {
    @Published var showFont1        = true
    @Published var showFont2        = true
    @Published var drawMetrics      = false
    @Published var drawUnderLine    = false
    @Published var drawBoundingBox  = false
    @Published var drawAnchors      = false
    @Published var coloredItems     = true
    // This is used to force update view when fonts change
    @Published var toggleRefresh    = false
    @Published var fontSize: Double = 100
}

struct HBStringView: View, DropDelegate {
    @Environment(\.openURL) var openURL
    //@EnvironmentObject var hbProject: HBProject
    @StateObject var stringViewSettings = HBStringViewSettings()
    
    @StateObject var hbProject = HBProject()

    var body: some View {
        NavigationView() {
            // Sidebar
            HBStringSidebarView(stringViewSettings: stringViewSettings)
            
            // Main Content
            VSplitView {
                VStack {
                    // The text field where we input text
                    TextField(Hibizcus.UIString.TestStringPlaceHolder, text: $hbProject.hbStringViewText)
                        .font(.title)
                        .onChange(of: hbProject.hbFont1.selectedScript) { newScript in
                            // Update layout data for both fonts when script is changed
                            hbProject.hbFont2.selectedScript = newScript
                            hbProject.refresh()
                        }
                        .onChange(of: hbProject.hbFont1.selectedLanguage) { newLanguage in
                            // Update layout data for both fonts when language is changed
                            hbProject.hbFont2.selectedLanguage = newLanguage
                            hbProject.refresh()
                        }
                    // The text to display the unicodes of the string
                    HStack {
                        Text(hbProject.hbStringViewText.hexString())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.body)
                            .foregroundColor(.blue)
                            .padding(.vertical, 3)
                        Spacer()
                        Button(action: copyHexString, label: {
                            Image(systemName: "doc.on.doc")
                        })
                        .padding(.vertical, 3)
                        .padding(.trailing, 5)
                        .foregroundColor(.primary)
                        .help("Copy hex string to clipboard")
                    }
                    .padding(.leading, 5)
                    .padding(.trailing, 5)
                    if hbProject.hbFont1.fileUrl != nil || hbProject.hbFont2.fileUrl != nil {
                        // Our custom view to display the shaped text
                        HBStringLayoutViewRepresentable(fontSize: stringViewSettings.fontSize,
                                                        slData1: hbProject.hbFont1.getStringLayoutData(forText: hbProject.hbStringViewText),
                                                        slData2: hbProject.hbFont2.getStringLayoutData(forText: hbProject.hbStringViewText),
                                                        stringViewSettings: stringViewSettings)
                            .onDrop(of: ["public.text", "public.truetype-ttf-font", "public.file-url"], delegate: self)
                            .onDrag({
                                let dragData = jsonFrom(font1: hbProject.hbFont1.fileUrl!.absoluteString, font2: hbProject.hbFont2.fileUrl!.absoluteString, text: hbProject.hbStringViewText)
                                UserDefaults.standard.setValue(dragData, forKey: "droppedjson")
                                print("Dragging out \(dragData)")
                                return NSItemProvider(item: dragData as NSString, typeIdentifier: kUTTypeText as String)
                            })
                    }
                    else {
                        VStack {
                            Spacer()
                            Text(Hibizcus.UIString.DragAndDropGridItemOrTwoFontFiles)
                                .font(.title)
                                .padding(.vertical, 50)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                    }
                }
                if hbProject.hbStringViewText.count > 0 {
                    Divider()
                    VStack {
                        HStack {
                            // Glyphs in the shaped text, shaped using font1, the main font
                            VStack {
                                StringGlyphListView(stringViewSettings:stringViewSettings,
                                                    defaultColor: (hbProject.hbFont2.fileUrl == nil) ? Color.primary : Hibizcus.FontColor.MainFontUIColor.opacity(0.8),
                                                    mainFont: true)
                            }
                            .padding(.leading, 10)
                            if hbProject.hbFont2.fileUrl != nil {
                                Divider()
                                // Glyphs in the shaped text, shaped font2, the compare font
                                VStack {
                                    StringGlyphListView(stringViewSettings:stringViewSettings,
                                                        defaultColor: (hbProject.hbFont2.fileUrl == nil) ? Color.primary : Hibizcus.FontColor.CompareFontUIColor.opacity(0.8),
                                                        mainFont: false)
                                }
                                .padding(.trailing, 10)
                            }
                        }
                    }
                }
            }
        }
        .environmentObject(hbProject)
        .toolbar {
            // Toggle sidebar
            ToolbarItem(placement: .navigation) {
                Button(action: toggleLeftSidebar, label: {
                    Image(systemName: "sidebar.left")
                })
            }
        }
        .onOpenURL(perform: { url in
            print("Url opened = \(url.absoluteString)")
            let params = url.queryParameters
            if params != nil {
                if params!["font1BookMark"] != nil && params!["font1BookMark"] != "" {
                    let bookMarkData = Data(base64Encoded: params!["font1BookMark"]!)
                    hbProject.hbFont1.loadFontWith(fontBookmark: bookMarkData!, fontSize: 40)
                }
                if params!["font2BookMark"] != nil && params!["font2BookMark"] != "" {
                    let bookMarkData = Data(base64Encoded: params!["font2BookMark"]!)
                    hbProject.hbFont2.loadFontWith(fontBookmark: bookMarkData!, fontSize: 40)
                }
                if params!["font1Url"] != nil && params!["font1Url"] != "" {
                    hbProject.hbFont1.setFontFile(filePath: params!["font1Url"]!)
                }
                if params!["font2Url"] != nil && params!["font2Url"] != "" {
                    hbProject.hbFont2.setFontFile(filePath: params!["font2Url"]!)
                }
                if params!["text"] != nil {
                    hbProject.hbStringViewText = params!["text"]!
                }
            }
        })
        .onDrop(of: ["public.text", "public.truetype-ttf-font", "public.file-url"], delegate: self)
        .navigationTitle(Text("StringViewer: \(hbProject.projectName)"))
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard info.hasItemsConforming(to: ["public.file-url"]) || info.hasItemsConforming(to: ["public.text"]) else {
            return false
        }
        
        if info.hasItemsConforming(to: ["public.text"]) {
            // This is JSON data
            guard let itemProvider = info.itemProviders(for: [(kUTTypeText as String)]).first else { return false }
            
            itemProvider.loadItem(forTypeIdentifier: (kUTTypeText as String), options: nil) {item, error in
                if item != nil {
                    // Cheating
                    let droppedData = UserDefaults.standard.string(forKey: "droppedjson")
                    let jsonData = droppedData!.data(using: .utf8)!
                    do {
                        let dictionary = try JSONDecoder().decode([String:String].self, from: jsonData)
                        
                        //let f1 = dictionary["font1"]
                        //let f2 = dictionary["font2"]
                        let tx = dictionary["text"]
                        if tx != nil {
                            DispatchQueue.main.async {
                                hbProject.hbStringViewText = tx!
                            }
                        }
                    }
                    catch{
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
        }
        else {
            guard let itemProvider = info.itemProviders(for: [(kUTTypeFileURL as String)]).first else { return false }
            
            itemProvider.loadItem(forTypeIdentifier: (kUTTypeFileURL as String), options: nil) {item, error in
                guard let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                // There should be a better way to determine filetype
                let urlstring = url.absoluteString.lowercased()
                if urlstring.hasSuffix(".ttf") || urlstring.hasSuffix(".otf") || urlstring.hasSuffix(".ttc") {
                //if url.absoluteString.hasSuffix(".ttf") || url.absoluteString.hasSuffix(".otf") || url.absoluteString.hasSuffix(".ttc") {
                    DispatchQueue.main.async {
                        if hbProject.hbFont1.fileUrl == nil {
                            hbProject.hbFont1.setFontFile(filePath: url.path)
                            // Update the string layout data with our new font
//                            updateStringLayoutData(forFont1: true, forFont2: false)
                        } else {
                            hbProject.hbFont2.setFontFile(filePath: url.path)
                            // Update the string layout data with our new font
//                            updateStringLayoutData(forFont1: false, forFont2: true)
                        }
                        hbProject.refresh() // .lastUpdated = NSDate().timeIntervalSince1970.debugDescription
                        // Just toggle this flag to force update the UI
                        //stringViewSettings.toggleRefresh.toggle()
                    }
                }
            }
        }
        
        return true
    }
    
    func copyHexString() {
        NSPasteboard.general.clearContents()
        if !NSPasteboard.general.setString(hbProject.hbStringViewText.hexString(), forType: NSPasteboard.PasteboardType.string) {
            print("Error setting string in pasteboard")
        }
        else {
            postNotification(title: "StringViewer", message: "\(hbProject.hbStringViewText.hexString()) copied to clipboard")
        }
    }
    
    func jsonFrom(font1:String, font2:String, text:String) -> String {
        let data = [
            "font1": font1,
            "font2": font2,
            "text": text
        ]
        
        let dataInJson = try! JSONEncoder().encode(data)
        return String(data: dataInJson, encoding: .utf8)!
    }
}

