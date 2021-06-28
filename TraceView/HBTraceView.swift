//
//  TraceView.swift
//
//  Created by Muthu Nedumaran on 24/2/21.
//

import Combine
import SwiftUI
import AppKit

class HBTraceViewOptions: ObservableObject {
    @Published var showFullTrace:Bool   = false
    @Published var showCluster:Bool     = false
    @Published var showGlyphNames:Bool  = false
    var fontBookmark1 = Data()
    var fontBookmark2 = Data()
}

struct HBTraceView: View, DropDelegate {
    @Environment(\.openURL) var openURL

    // This does not update the saved project as that data is not shared across other windows
    // SwiftUI limitation?
    @StateObject var hbProject = HBProject()
    @State var traceText = ""
    @State var traceId = ""
    
    @ObservedObject var hbTraceBridge: HBTracerBridge = HBTracerBridge.shared
    @ObservedObject var traceViewOptions = HBTraceViewOptions()
    
    var body: some View {
        NavigationView() {
            HBTraceSideBarView(traceViewData: traceViewOptions)
            VStack {
                VStack {
                    TextField(Hibizcus.UIString.TestStringPlaceHolder, text: $traceText)// hbTraceBridge.theText)
                        .font(.title)
                        .onChange(of: traceText /*hbTraceBridge.theText*/) { _ in
                            hbTraceBridge.theText = traceText
                            hbProject.hbTraceViewText = hbTraceBridge.theText
                            /*hbTraceBridge.*/startTrace()
                        }
                        .onChange(of: hbProject.hbFont1.selectedLanguage, perform: { newLanguage in
                            hbTraceBridge.theText = traceText
                            /*hbTraceBridge.*/startTrace()
                        })
                        .onChange(of: hbProject.hbFont1.fileUrl, perform: { value in
                            hbTraceBridge.theText = traceText
                            /*hbTraceBridge.*/startTrace()
                        })
                    HStack {
                        Text(traceText.hexString()) // hbTraceBridge.theText.hexString())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.body)
                            .foregroundColor(.blue)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 5)
                        Spacer()
                        Button(action: copyHexString, label: {
                            Image(systemName: "doc.on.doc")
                        })
                        .padding(.bottom, 5)
                        .padding(.trailing, 5)
                        .foregroundColor(.primary)
                        .help("Copy hex string to clipboard")
                    }
                }
                .border(Color.primary.opacity(0.3), width: 1)
                if hbProject.hbFont1.ctFont != nil && hbProject.hbFont1.fileUrl != nil {
                    List {
                        ForEach(hbTraceBridge.tvLogItems) { logItem in
                            if (traceViewOptions.showFullTrace || logItem.didShape) && (logItem.traceId == /*hbTraceBridge.*/traceId) {
                                TraceLog(tvLogItem: logItem, ctFont: hbProject.hbFont1.ctFont!, viewOptions: traceViewOptions)
                            }
                        }
                    }
                    .padding(.horizontal, 0)
                    .padding(.vertical, 1)
                } else {
                    Spacer()
                    Text(Hibizcus.UIString.DragAndDropOneFontFile)
                        .font(.title)
                        .padding(.vertical, 50)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            }
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
                        if hbTraceBridge.theText != "" {
                            copyTextToClipboard(textToCopy: hbTraceBridge.theText)
                        }
                    }, label: {
                        //Image(systemName: "doc.on.doc")
                        Text("Copy text")
                    })
                    .help((hbTraceBridge.theText != "") ? "Copy \(hbTraceBridge.theText) to clipboard" : "")
                    .disabled(hbTraceBridge.theText == "")
                }
                
                // String Viewer
                ToolbarItem(placement: ToolbarItemPlacement.automatic) {
                    Button(action: {
                        if let url = URL(string: "Hibizcus://stringview?\(urlParamsForToolWindow(text: hbTraceBridge.theText))") {
                            openURL(url)
                        }
                    }, label: {
                        //Image(systemName: "rectangle.and.text.magnifyingglass")
                        Text("String viewer")
                    })
                    .help(hbTraceBridge.theText != "" ? "Open \(hbTraceBridge.theText) in StringViewer" : "Open StringViewer")
                } 
            }
            .onDrop(of: ["public.text", "public.truetype-ttf-font", "public.file-url"], delegate: self)
            .navigationTitle(Text("TraceViewer: \(hbProject.projectName)"))
        }
        .environmentObject(hbProject)
        .onOpenURL(perform: { url in
            print("Url opened = \(url.absoluteString)")
            let params = url.queryParameters
            if params != nil {
                updateTextAndFonts(params: params!)
                hbTraceBridge.tvLogItems.removeAll()
                //hbTraceBridge.hbFont  = hbProject.hbFont1
                /*hbTraceBridge.*/startTrace()
            }
        })
    }
    
    func startTrace() {
        hbTraceBridge.removeItemsFor(traceId: traceId)
        traceId = NSDate().timeIntervalSince1970.debugDescription
        hbTraceBridge.startTrace(traceId: traceId, hbFont: hbProject.hbFont1)
    }
    
    func copyHexString() {
        NSPasteboard.general.clearContents()
        if !NSPasteboard.general.setString(hbTraceBridge.theText.hexString(), forType: NSPasteboard.PasteboardType.string) {
            print("Error setting string in pasteboard")
        } else {
            postNotification(title: "TraceViwer", message: "\(hbTraceBridge.theText.hexString()) copied to clipboard")
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
                            hbTraceBridge.tvLogItems.removeAll()
                            updateTextAndFonts(params: dictionary)
                            /*hbTraceBridge.*/startTrace()
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
                        hbProject.hbFont1.setFontFile(filePath: url.path)
                        //hbTraceBridge.hbFont = hbProject.hbFont1
                        /*hbTraceBridge.*/startTrace()
                    }
                }
            }
        }
        
        return true
    }
    
    func updateTextAndFonts(params: [String: String]) {
        /*
        if params["font1BookMark"] != nil && params["font1BookMark"] != "" {
            let bookMarkData = Data(base64Encoded: params["font1BookMark"]!)
            hbProject.hbFont1.loadFontWith(fontBookmark: bookMarkData!, fontSize: 40)
            // Save the bookmark
            traceViewOptions.fontBookmark1 = bookMarkData!
        }
        if params["font2BookMark"] != nil && params["font2BookMark"] != "" {
            let bookMarkData = Data(base64Encoded: params["font2BookMark"]!)
            hbProject.hbFont2.loadFontWith(fontBookmark: bookMarkData!, fontSize: 40)
            // Save the bookmark
            traceViewOptions.fontBookmark2 = bookMarkData!
        }
        if params["font1Url"] != nil && params["font1Url"] != "" {
            hbProject.hbFont1.setFontFile(filePath: params["font1Url"]!)
        }
        if params["font2Url"] != nil && params["font2Url"] != "" {
            hbProject.hbFont2.setFontFile(filePath: params["font2Url"]!)
        }
        if params["text"] != nil {
            hbTraceBridge.theText = params["text"]!
        } */
        
        // Font 1
        if params["font1BookMark"] != nil && params["font1BookMark"] != "" {
            // Load from bookmark
            let bookMarkData = Data(base64Encoded: params["font1BookMark"]!)
            hbProject.hbFont1.loadFontWith(fontBookmark: bookMarkData!, fontSize: 40)
            // Save the bookmark
            traceViewOptions.fontBookmark1 = bookMarkData!
        }
        else if params["font1Url"] != nil && params["font1Url"] != "" {
            // Load from URL
            hbProject.hbFont1.setFontFile(filePath: params["font1Url"]!)
        }
        else if params["font1Script"] != nil && params["font1Script"] != "" {
            // Load system font
            hbProject.hbFont1.loadFontFor(script: params["font1Script"]!, fontSize: 40, charsInScript: params["font1Chars"]!)
        }
        
        // Font 2
        if params["font2BookMark"] != nil && params["font2BookMark"] != "" {
            let bookMarkData = Data(base64Encoded: params["font2BookMark"]!)
            hbProject.hbFont2.loadFontWith(fontBookmark: bookMarkData!, fontSize: 40)
            traceViewOptions.fontBookmark2 = bookMarkData!
        }
        else if params["font2Url"] != nil && params["font2Url"] != "" {
            hbProject.hbFont2.setFontFile(filePath: params["font2Url"]!)
        }
        else if params["font2Script"] != nil && params["font2Script"] != "" {
            // Load system font
            hbProject.hbFont2.loadFontFor(script: params["font2Script"]!, fontSize: 40, charsInScript: params["font2Chars"]!)
        }
        
        // The text
        if params["text"] != nil {
            traceText = params["text"]!
            hbTraceBridge.theText = traceText //params["text"]!
        }
        
        hbProject.projectName = params["project"]!
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
        
        if traceViewOptions.fontBookmark1.count > 0 {
            bkMk1 = traceViewOptions.fontBookmark1.base64EncodedString() //document.projectData.fontFile1Bookmark!.base64EncodedString()
        } else if hbProject.hbFont1.fileUrl != nil {
            f1Url = hbProject.hbFont1.fileUrl?.absoluteString ?? ""
        } else {
            scrp1 = hbProject.hbFont1.selectedScript
            chrs1 = hbProject.hbFont1.charsInScript
        }
        
        if traceViewOptions.fontBookmark2.count > 0 {
            bkMk2 = traceViewOptions.fontBookmark2.base64EncodedString() // document.projectData.fontFile2Bookmark!.base64EncodedString()
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

struct TraceLog: View {
    var tvLogItem:TVLogItem
    var ctFont:CTFont
    @ObservedObject var viewOptions:HBTraceViewOptions
    
    var body: some View {
        HStack {
            ZStack {
                Text("")
                    .font(.callout)
                    .frame(width: 100, height: 100/*viewOptions.showGlyphNames ? 100 : 80*/, alignment: .leading)
                    .border(Color.primary.opacity(0.3), width: 1)
                Text(tvLogItem.message) //  + " " + tvLogItem.traceId) // for debugging
                    .font(.callout)
                    .frame(width: 80, height: 90/*viewOptions.showGlyphNames ? 90 : 70*/, alignment: .leading)
            }
            HBTraceRowViewRepresentable(tvLogItem: tvLogItem, ctFont: ctFont, viewOptions: viewOptions)
                .frame(height:100/*viewOptions.showGlyphNames ? 100 : 80*/)
                .padding(.horizontal, 0)
                .border(Color.primary.opacity(0.3), width: 1)
        }
    }
}

