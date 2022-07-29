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
    var fontBookmark1 = Data()
    var fontBookmark2 = Data()
}

struct HBStringView: View, DropDelegate {
    @Environment(\.openURL) var openURL

    // This does not update the saved project as that data is not shared across other windows
    // SwiftUI limitation?
    @StateObject var stringViewSettings = HBStringViewSettings()
    @StateObject var hbProject = HBProject()
    @State var listViewOpen = true
    
    let pubFontFileChanged = NotificationCenter.default.publisher(for: NSNotification.Name(Hibizcus.Messages.FontFileChanged))

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
                            hbProject.refresh() }
                        .onChange(of: hbProject.hbFont1.selectedLanguage) { newLanguage in
                            // Update layout data for both fonts when language is changed
                            hbProject.hbFont2.selectedLanguage = newLanguage
                            hbProject.refresh() }
                        .onChange(of: hbProject.hbFont1.selectedShaper) { _ in
                            hbProject.refresh() }
                        .onChange(of: hbProject.hbFont2.selectedShaper) { _ in
                            hbProject.refresh() }
                    if  hbProject.hbFont1.available || hbProject.hbFont2.available {
                        // Our custom view to display the shaped text
                        HBStringLayoutViewRepresentable(fontSize: stringViewSettings.fontSize,
                                                        slData1: hbProject.hbFont1.getStringLayoutData(forText: hbProject.hbStringViewText),
                                                        slData2: hbProject.hbFont2.getStringLayoutData(forText: hbProject.hbStringViewText),
                                                        stringViewSettings: stringViewSettings)
                            .onDrop(of: ["public.text", "public.truetype-ttf-font", "public.file-url"], delegate: self)
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
                
                // The text to display the unicodes of the string
                HStack {
                    Button(action: copyHexString, label: {
                        Image(systemName: "doc.on.doc")
                    })
                    Text(hbProject.hbStringViewText.hexString())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.body)
                        .foregroundColor(.blue)
                        .padding(.vertical, 3)
                    Spacer()
                    Button(action: {listViewOpen = !listViewOpen}, label: {
                        Image(systemName: "rectangle.bottomthird.inset.fill")
                    })
                    .padding(.vertical, 3)
                    .padding(.trailing, 5)
                    .foregroundColor(.primary)
                    .help("Copy hex string to clipboard")
                }
                .padding(.leading, 5)
                .padding(.trailing, 5)
                
                // Glyph ListView
                if hbProject.hbStringViewText != "" && listViewOpen {
                    Divider()
                    VStack {
                        HStack {
                            // Glyphs in the shaped text, shaped using font1, the main font
                            VStack {
                                StringGlyphListView(stringViewSettings:stringViewSettings,
                                                    defaultColor: (hbProject.hbFont2.available) ? Color.primary : Hibizcus.FontColor.MainFontUIColor.opacity(0.8),
                                                    mainFont: true)
                            }
                            .padding(.leading, 10)
                            if hbProject.hbFont2.available {
                                Divider()
                                // Glyphs in the shaped text, shaped font2, the compare font
                                VStack {
                                    StringGlyphListView(stringViewSettings:stringViewSettings,
                                                        defaultColor: (hbProject.hbFont2.available) ? Color.primary : Hibizcus.FontColor.CompareFontUIColor.opacity(0.8),
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
            // Copy buton
            ToolbarItem(placement: ToolbarItemPlacement.automatic) {
                Button(action: {
                    if hbProject.hbStringViewText != "" {
                        copyTextToClipboard(textToCopy: hbProject.hbStringViewText)
                    }
                }, label: {
                    //Image(systemName: "doc.on.doc")
                    Text("Copy text")
                })
                .help( hbProject.hbStringViewText != "" ? "Copy \(hbProject.hbStringViewText) to clipboard" : "")
                .disabled(hbProject.hbStringViewText == "")
            }
            // TraceView
            ToolbarItem(placement: ToolbarItemPlacement.automatic) {
                Button(action: {
                    if let url = URL(string: "Hibizcus://traceview?\(urlParamsForToolWindow(text: hbProject.hbStringViewText))") {
                        openURL(url)
                    }
                }, label: {
                    //Image(systemName: "list.bullet.rectangle")
                    Text("Trace viewer")
                })
                .help( hbProject.hbStringViewText != "" ? "Open \(hbProject.hbStringViewText) in TraceViewer" : "Open TraceViewer")
                .disabled(hbProject.hbFont1.fileUrl == nil)
            }
        }
        .onOpenURL(perform: { url in
            //print("Url opened = \(url.absoluteString)")
            let params = url.queryParameters
            if params != nil {
                updateTextAndFonts(params: params!)
            }
        })
        .onDrop(of: ["public.text", "public.truetype-ttf-font", "public.file-url"], delegate: self)
        .navigationTitle(Text("StringViewer: \(hbProject.projectName)"))
        .onReceive(pubFontFileChanged) { _ in
            print("Notification about filechange received!")
            hbProject.refresh()
        }
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
                        // Update should be done on the main thread
                        DispatchQueue.main.async {
                            updateTextAndFonts(params: dictionary)
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
                    DispatchQueue.main.async {
                        if hbProject.hbFont1.fileUrl == nil {
                            hbProject.hbFont1.setFontFile(filePath: url.path)
                        } else {
                            hbProject.hbFont2.setFontFile(filePath: url.path)
                        }
                        hbProject.refresh() 
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
    
    func updateTextAndFonts(params: [String: String]) {
        // load Fonts if Font1 is not loaded
        if !hbProject.hbFont1.available {
            if params["font1BookMark"] != nil && params["font1BookMark"] != "" {
                // Load from bookmark
                let bookMarkData = Data(base64Encoded: params["font1BookMark"]!)
                hbProject.hbFont1.loadFontWith(fontBookmark: bookMarkData!, fontSize: 40)
                // Save the bookmark
                stringViewSettings.fontBookmark1 = bookMarkData!
            }
            else if params["font1Url"] != nil && params["font1Url"] != "" {
                // Load from URL
                hbProject.hbFont1.setFontFile(filePath: params["font1Url"]!)
            }
            else if params["font1Script"] != nil && params["font1Script"] != "" {
                // Load system font
                hbProject.hbFont1.loadFontFor(script: params["font1Script"]!, fontSize: 40, charsInScript: params["font1Chars"]!)
            }

            if params["font2BookMark"] != nil && params["font2BookMark"] != "" {
                let bookMarkData = Data(base64Encoded: params["font2BookMark"]!)
                hbProject.hbFont2.loadFontWith(fontBookmark: bookMarkData!, fontSize: 40)
                stringViewSettings.fontBookmark2 = bookMarkData!
            }
            else if params["font2Url"] != nil && params["font2Url"] != "" {
                hbProject.hbFont2.setFontFile(filePath: params["font2Url"]!)
            }
            else if params["font2Script"] != nil && params["font2Script"] != "" {
                // Load system font
                hbProject.hbFont2.loadFontFor(script: params["font2Script"]!, fontSize: 40, charsInScript: params["font2Chars"]!)
            }
        }
        
        // Set the text if current text is blank, append otherwise
        if params["text"] != nil {
            if hbProject.hbStringViewText.isEmpty {
                hbProject.hbStringViewText = params["text"]!
            }
            else {
                hbProject.hbStringViewText.append(" \(params["text"]!)")
            }
        }
        
        if hbProject.projectName.isEmpty {
            hbProject.projectName = params["project"]!
        }
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
        
        if stringViewSettings.fontBookmark1.count > 0 {
            bkMk1 = stringViewSettings.fontBookmark1.base64EncodedString() //document.projectData.fontFile1Bookmark!.base64EncodedString()
        } else if hbProject.hbFont1.fileUrl != nil {
            f1Url = hbProject.hbFont1.fileUrl?.absoluteString ?? ""
        } else {
            scrp1 = hbProject.hbFont1.selectedScript
            chrs1 = hbProject.hbFont1.charsInScript
        }
        
        if stringViewSettings.fontBookmark2.count > 0 {
            bkMk2 = stringViewSettings.fontBookmark2.base64EncodedString() // document.projectData.fontFile2Bookmark!.base64EncodedString()
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


