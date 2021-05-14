//
//  TraceView.swift
//
//  Created by Muthu Nedumaran on 24/2/21.
//

import Combine
import SwiftUI
import AppKit

class TraceViewOptions: ObservableObject {
    @Published var showFullTrace:Bool   = false
    @Published var showCluster:Bool     = false
    @Published var showGlyphNames:Bool  = false
}

struct TraceView: View, DropDelegate {
    @EnvironmentObject var hbProject: HBProject

    @ObservedObject var hbTraceBridge: TracerBridge = TracerBridge.shared
    @ObservedObject var traceViewOptions = TraceViewOptions()
    
    var body: some View {
        NavigationView() {
            TraceSideBarView(traceViewData: traceViewOptions)
            VStack {
                VStack {
                    TextField(Hibizcus.UIString.TestStringPlaceHolder, text: $hbTraceBridge.theText)
                        .font(.title)
                        .onChange(of: hbTraceBridge.theText) { _ in
                            hbProject.hbTraceViewText = hbTraceBridge.theText
                            hbTraceBridge.startTrace()
                        }
                        .onChange(of: hbProject.hbFont1.selectedLanguage, perform: { newLanguage in
                            hbTraceBridge.startTrace()
                        })
                    HStack {
                        Text(hbTraceBridge.theText.hexString())
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
                            if (traceViewOptions.showFullTrace || logItem.didShape) && (logItem.traceId == hbTraceBridge.traceId) {
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
            }
            .onDrop(of: ["public.text", "public.truetype-ttf-font", "public.file-url"], delegate: self)
            .navigationTitle(Text("TraceViewer: \(hbProject.projectName)"))
        }
        .onAppear {
            hbTraceBridge.hbFont    = hbProject.hbFont1
            hbTraceBridge.theText   = hbProject.hbTraceViewText
            hbTraceBridge.startTrace()
        }
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
                        
                        //let f1 = dictionary["font1"]
                        let tx = dictionary["text"]
                        
                        DispatchQueue.main.async {
                            hbTraceBridge.tvLogItems.removeAll()
                            //hbProject.hbFont1.setFontFile(filePath: f1!)
                            //hbTraceBridge.hbFont = hbProject.hbFont1
                            hbTraceBridge.theText = tx!
                            hbTraceBridge.startTrace()
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
                        hbProject.hbFont1.setFontFile(filePath: url.path)
                        hbTraceBridge.hbFont = hbProject.hbFont1
                        hbTraceBridge.startTrace()
                    }
                }
            }
        }
        
        return true
    }
}

struct TraceLog: View {
    var tvLogItem:TVLogItem
    var ctFont:CTFont
    @ObservedObject var viewOptions:TraceViewOptions
    
    var body: some View {
        HStack {
            ZStack {
                Text("")
                    .font(.callout)
                    .frame(width: 100, height: 80, alignment: .leading)
                    .border(Color.primary.opacity(0.3), width: 1)
                Text(tvLogItem.message) //  + " " + tvLogItem.traceId) // for debugging
                    .font(.callout)
                    .frame(width: 80, height: 70, alignment: .leading)
            }
            TraceRowViewRepresentable(tvLogItem: tvLogItem, ctFont: ctFont, viewOptions: viewOptions)
                .frame(height:80)
                .padding(.horizontal, 0)
                .border(Color.primary.opacity(0.3), width: 1)
        }
    }
}

