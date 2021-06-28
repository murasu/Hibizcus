//
//  WordsView.swift
//
//  Created by Muthu Nedumaran on 24/2/21.
//

import Combine
import SwiftUI
import AppKit

enum HBGridViewTab {
    case FontsTab, ClustersTab, WordsTab, NumbersTab
}

enum HBGridItemItemType {
    case Glyph, Cluster, Word, Number
}

class HBProject: ObservableObject {
    @Published var projectName      = ""
    @Published var hbFont1          = HBFont(filePath: "", fontSize: 40)
    @Published var hbFont2          = HBFont(filePath: "", fontSize: 40)
    @Published var hbGridViewText   = ""
    @Published var hbStringViewText = ""
    @Published var hbTraceViewText  = ""
    // Holds the last updated timestamp. Used to force change the value for UI updates
    @Published var lastUpdated      = ""
    
    func refresh() {
        self.lastUpdated = NSDate().timeIntervalSince1970.debugDescription
    }
}

struct HBGridItem : Hashable {
    var type: HBGridItemItemType?
    var text: String?//    = ""
    var id              = UUID()                    // Unique ID for this item
    var glyphIds        = [kCGFontIndexInvalid,     // For Font1 and Font2
                           kCGFontIndexInvalid]
    var width           = [CGFloat(0),
                           CGFloat(0)]
    var height          = CGFloat(0)                // The rest of the data is for Font1 only
    var lsb             = CGFloat(0)
    var rsb             = CGFloat(0)
    var label           = ""                        // Stores the glyph name in the case of font comparison
    var uniLabel        = ""                        // Label that holds the unicode value
    var diffWidth       = false
    var diffGlyf        = false
    var diffLayout      = false
    var colorGlyphs     = false
    func hasDiff(excludeOutlines: Bool) -> Bool {
        if excludeOutlines {
            return diffWidth || diffLayout
        }
        return diffGlyf || diffWidth || diffLayout
    }
}

class HBGridViewOptions: ObservableObject {
    @Published var matchOption: String          = WordSearchOptions.string.rawValue
    @Published var digitsOption: String         = NumberOfDigits.three.rawValue
    @Published var highlightPattern: Bool       = false         // To highlight the search pattern in matches, currently not used
    @Published var compareWordLayout: Bool      = false         // To initiate layout comparison in Words tab when 2 fonts are used
    @Published var showDiffsOnly: Bool          = false         // Only show the items that are different when two fonts are used
    @Published var currentTab: HBGridViewTab    = .FontsTab     // The currently active tab
    @Published var runningComparisons: Bool     = false         // Flag to indicate a comparison is running, so the UI can show activity
    @Published var showThousand: Bool           = false         // Insert a comma to show thousand in numbers with >= 4 digits
    @Published var showLakh: Bool               = false         // Insert a comma to show Lakh in a six digit number.
    @Published var colorGlyphs: Bool            = false         // Show each glyph in a different color - used in Cluster tab
    @Published var wordlistAvailable: Bool      = true          // Flag to indicate if wordlist is availabe for current script
    @Published var showUnicodesOnly: Bool       = false         // Only show glyphs with Unicodes. Font tab only
    @Published var showASCIIDigits: Bool        = false         // Show digits 0-9 instead of native ones
    @Published var dontCompareOutlines: Bool    = false         // By default outlines are compared. Set this to true to disable
}

struct HBGridView: View, DropDelegate {
    @Environment(\.openURL) var openURL
    @Binding var document: HibizcusDocument
    
    @StateObject var hbProject = HBProject()
    var projectFileUrl: URL?

    @StateObject var clusterViewModel           = HBGridSidebarClusterViewModel()
    @StateObject var gridViewOptions            = HBGridViewOptions()
    
    // Used across all tabs
    @State var hbGridItems                      = [HBGridItem]()
    @State var minCellWidth: CGFloat            = 100
    @State var maxCellWidth: CGFloat            = 100  // 150
    @State var searchItem: String               = ""
    
    // Used in FontTab
    @State var glyphItems                       = [HBGridItem]()
    @State var glyphCellWidth:CGFloat           = 100
    
    // Used in Words tab
    @State var theText                          = ""
    
    @State var showGlyphView                    = false
    @State var tappedItem                       = HBGridItem()
    
    var body: some View {
        NavigationView() {
            HBGridSidebarView(gridViewOptions: gridViewOptions, clusterViewModel: clusterViewModel)
                .onChange(of: gridViewOptions.matchOption) { value in
                    print("Time to refresh search with \(gridViewOptions.matchOption) for script \(hbProject.hbFont1.selectedScript) in language \(hbProject.hbFont1.selectedLanguage)")
                    refreshGridItems() }
                .onChange(of: gridViewOptions.compareWordLayout) { value in
                    refreshGridItems() }
                .onChange(of: gridViewOptions.digitsOption) { value in
                    refreshGridItems() }
                .onChange(of: gridViewOptions.showUnicodesOnly) { value in
                    refreshGridItems() }
                .onChange(of: gridViewOptions.showASCIIDigits) { value in
                    refreshGridItems() }
                .onChange(of: gridViewOptions.dontCompareOutlines) { value in
                    hbProject.refresh() }
                .onChange(of: gridViewOptions.showThousand) { value in
                    if gridViewOptions.showLakh {
                        gridViewOptions.showThousand = true
                    }
                    updateNumberItems() }
                .onChange(of: gridViewOptions.showLakh) { value in
                    if value {
                        gridViewOptions.showThousand = true
                    }
                    updateNumberItems() }
                .onChange(of: gridViewOptions.colorGlyphs) { value in
                    if hbProject.hbFont2.available {
                        // Do not allow color if we are comparing
                        gridViewOptions.colorGlyphs = false
                    }
                    refreshGridItems() }
                .onChange(of: gridViewOptions.currentTab) { newTab in
                    print("Tab switched to \(newTab)")
                    glyphItems.removeAll()
                    refreshGridItems() }
                .onChange(of: hbProject.hbFont1.selectedScript) { newScript in
                    print("Script has changed from \(clusterViewModel.currentScript) to \(newScript)")
                    clusterViewModel.currentScript = newScript
                    // Save this to project if we have a character string
                    if hbProject.hbFont1.charsInScript != "" {
                        document.projectData.systemFont1Script = newScript
                        document.projectData.systemFont1Chars = hbProject.hbFont1.charsInScript
                    } else {
                        document.projectData.systemFont1Script = ""
                        document.projectData.systemFont1Chars = ""
                    }
                    glyphItems.removeAll()
                    refreshGridItems() }
                .onChange(of: hbProject.hbFont1.selectedLanguage) { newLanguage in
                    print("Language has changed to \(newLanguage)")
                    glyphItems.removeAll()
                    refreshGridItems() }
                .onChange(of: hbProject.hbFont1.fileWatcher.fontFileChanged) { _ in
                    print("Font file changed - need to redraw the UI")
                    hbProject.refresh() }
                .onChange(of: hbProject.hbFont2.fileWatcher.fontFileChanged) { _ in
                    print("Font file changed - need to redraw the UI")
                    hbProject.refresh() }
                .onChange(of: hbProject.hbFont1.fileUrl) { _ in
                    // Remove the bookmark if the font is removed from the project & vice-versa
                    updateFontBookmark(mainFont: true) }
                .onChange(of: hbProject.hbFont2.fileUrl) { _ in
                    // Remove the bookmark if the font is removed from the project & vice-versa
                    updateFontBookmark(mainFont: false) }
                .onChange(of: hbProject.hbFont2.selectedScript) { newScript in
                    // We don't care about the selected script in Font2 - but we want to refresh the
                    // grid in case a system font is loaded.
                    // Save this to project if we have a character string
                    if hbProject.hbFont2.charsInScript != "" {
                        document.projectData.systemFont2Script = newScript
                        document.projectData.systemFont2Chars = hbProject.hbFont2.charsInScript
                    } else {
                        document.projectData.systemFont2Script = ""
                        document.projectData.systemFont2Chars = ""
                    }
                    glyphItems.removeAll()
                    refreshGridItems() }
                .onChange(of: hbProject.hbFont1.selectedShaper) { _ in
                        glyphItems.removeAll()
                        refreshGridItems() }
                .onChange(of: hbProject.hbFont2.selectedShaper) { _ in
                        glyphItems.removeAll()
                        refreshGridItems() }
            VStack {
                if gridViewOptions.currentTab == HBGridViewTab.WordsTab {
                    VStack {
                        TextField(Hibizcus.UIString.TestStringPlaceHolder, text: $theText)
                            .font(.title)
                            .onChange(of: theText) { _ in
                                UserDefaults.standard.set(theText, forKey: Hibizcus.Key.WVString)
                                refreshGridItems()
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 5)
                        if ( gridViewOptions.currentTab == HBGridViewTab.WordsTab ) {
                            Text(theText.hexString())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.body)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 5)
                        }
                    }
                    .border(Color.primary.opacity(0.3), width: 1)
                }
                if hbProject.hbFont1.available {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: maxCellWidth))], spacing: 10) {
                            ForEach(hbGridItems, id: \.self) { hbGridItem in
                                if !gridViewOptions.showDiffsOnly || (gridViewOptions.showDiffsOnly
                                                                        && hbGridItem.hasDiff(excludeOutlines: gridViewOptions.dontCompareOutlines)) {
                                    HBGridCellViewRepresentable(gridItem: hbGridItem, gridViewOptions: gridViewOptions, scale: 1.0)
                                        .frame(width: maxCellWidth, height: 92, alignment: .center)
                                        .border(Color.primary.opacity(0.7), width: tappedItem==hbGridItem ||
                                                    (searchItem.count>0 && (hbGridItem.label.hasPrefix(searchItem) /*|| hbGridItem.text!.hasPrefix(searchItem)*/) ) ? 1 : 0)
                                        //.border(Color.primary.opacity(0.7), width: (searchItem.count>0 && hbGridItem.uniLabel.hasPrefix(searchItem)) ? 1 : 0)
                                        .gesture(TapGesture(count: 2).onEnded {
                                            // UI Update should be done on main thread
                                            DispatchQueue.main.async {
                                                tappedItem = hbGridItem
                                            }
                                            print("double clicked on item \(hbGridItem)")
                                            doubleClicked(clickedItem: hbGridItem)
                                        })
                                        .simultaneousGesture(TapGesture().onEnded {
                                            DispatchQueue.main.async {
                                                tappedItem = hbGridItem
                                            }
                                            print("single clicked on item \(hbGridItem)")
                                        })
                                        .onDrag({
                                            let dragData = paramsForToolWindow(asJson: true, text: hbGridItem.text!)
                                            UserDefaults.standard.setValue(dragData, forKey: "droppedjson")
                                            print("Dragging out \(dragData)")
                                            return NSItemProvider(item: dragData as NSString, typeIdentifier: kUTTypeText as String)
                                        })
                                        .sheet(isPresented: $showGlyphView, onDismiss: glyphViewDismissed) {
                                            HBGlyphView(document: $document, gridViewOptions: gridViewOptions, tappedItem: tappedItem, gridItems: hbGridItems)
                                        }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .background(Color(NSColor.textBackgroundColor))
                    }
                    Divider()
                    HStack {
                        Text(tappedItem.text ?? "")
                            .font(.system(size: 12, design: .monospaced))
                            .padding(.top, 1)
                            .padding(.bottom, 5)
                            .padding(.leading, 20)
                        Spacer()
                        Text("\(hbGridItems.count) Items")
                            .font(.system(size: 12, design: .monospaced))
                            .padding(.top, 1)
                            .padding(.bottom, 5)
                            .padding(.trailing, 20)
                    }
                } else {
                    Spacer()
                    Text(Hibizcus.UIString.DragAndDropTwoFontFiles)
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
                // Search : Only for fonts tab for now
                ToolbarItem(placement: ToolbarItemPlacement.automatic) {
                    TextField("Search glyph", text: $searchItem)
                        .font(.body)
                        .textFieldStyle(SquareBorderTextFieldStyle())
                        .frame(width: 150)//, height: 50)
                        .disabled(gridViewOptions.currentTab != HBGridViewTab.FontsTab)
                }
                
                // Copy buton
                ToolbarItem(placement: ToolbarItemPlacement.automatic) {
                    Button(action: {
                        if tappedItem.text != nil && tappedItem.text != "" {
                            copyTextToClipboard(textToCopy: tappedItem.text!)
                        }
                    }, label: {
                        //Image(systemName: "doc.on.doc")
                        Text("Copy text")
                    })
                    .help((tappedItem.text != nil && tappedItem.text != "") ? "Copy \(tappedItem.text!) to clipboard" : "")
                    .disabled(tappedItem.text == nil || tappedItem.text == "")
                }
                // String Viewer
                ToolbarItem(placement: ToolbarItemPlacement.automatic) {
                    Button(action: {
                        
                        if let url = URL(string: "Hibizcus://stringview?\(paramsForToolWindow(asJson: false, text: tappedItem.text ?? ""))") {
                            openURL(url)
                        }
                    }, label: {
                        //Image(systemName: "rectangle.and.text.magnifyingglass")
                        Text("String viewer")
                    })
                    .help((tappedItem.text != nil && tappedItem.text != "") ? "Open \(tappedItem.text!) in StringViewer" : "Open StringViewer")
                }
                // TraceView - only when font1 has file access
                ToolbarItem(placement: ToolbarItemPlacement.automatic) {
                    Button(action: {
                        if let url = URL(string: "Hibizcus://traceview?\(paramsForToolWindow(asJson: false, text: tappedItem.text ?? ""))") {
                            openURL(url)
                        }
                    }, label: {
                        //Image(systemName: "list.bullet.rectangle")
                        Text("Trace viewer")
                    })
                    .help((tappedItem.text != nil && tappedItem.text != "") ? "Open \(tappedItem.text!) in TraceViewer" : "Open TraceViewer")
                    .disabled(hbProject.hbFont1.fileUrl == nil)
                }
                
            }
            //.navigationTitle("Hiziscus Font Tools")
            .onChange(of: clusterViewModel.selectedBase) { _ in
                refreshGridItems()
            }
            .onChange(of: clusterViewModel.addNukta) { _ in
                refreshGridItems()
            }
            .onChange(of: clusterViewModel.selectedSubConsonant) { _ in
                refreshGridItems()
            }
            .onChange(of: clusterViewModel.selectedVowelSign) { _ in
                refreshGridItems()
            }
            .onChange(of: clusterViewModel.selectedOtherSign) { _ in
                refreshGridItems()
            }
            .onChange(of: clusterViewModel.justLoadedFromFile) { _ in
                clusterViewModel.justLoadedFromFile = false
                //refreshGridItems()
            }
        }
        .onDrop(of: ["public.truetype-ttf-font", "public.file-url"], delegate: self)
        .onAppear {
            // Load font1 from bookmark or system font for script and characters
            if document.projectData.fontFile1Bookmark != nil {
                hbProject.hbFont1.loadFontWith(fontBookmark: document.projectData.fontFile1Bookmark!, fontSize: 40)
            }
            else if document.projectData.systemFont1Script != nil {
                hbProject.hbFont1.loadFontFor(script: document.projectData.systemFont1Script!,
                                              fontSize: 40,
                                              charsInScript: document.projectData.systemFont1Chars!)
            }
            // Likewise font2
            if document.projectData.fontFile2Bookmark != nil {
                hbProject.hbFont2.loadFontWith(fontBookmark: document.projectData.fontFile2Bookmark!, fontSize: 40)
            }
            else if document.projectData.systemFont2Script != nil {
                hbProject.hbFont2.loadFontFor(script: document.projectData.systemFont2Script!,
                                              fontSize: 40,
                                              charsInScript: document.projectData.systemFont2Chars!)
            }
            
            if projectFileUrl != nil {
                hbProject.projectName = projectFileUrl!.lastPathComponent
            }
            
            clusterViewModel.currentScript = hbProject.hbFont1.selectedScript
            glyphItems.removeAll()
            hbProject.refresh()
            refreshGridItems()
        }
        .environmentObject(hbProject)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard info.hasItemsConforming(to: ["public.file-url"]) else {
            return false
        }
        
        guard let itemProvider = info.itemProviders(for: [(kUTTypeFileURL as String)]).first else { return false }
        
        itemProvider.loadItem(forTypeIdentifier: (kUTTypeFileURL as String), options: nil) {item, error in
            guard let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            // There should be a better way to determine filetype
            let urlstring = url.absoluteString.lowercased()
            if urlstring.hasSuffix(".ttf") || urlstring.hasSuffix(".otf") || urlstring.hasSuffix(".ttc") {
                DispatchQueue.main.async {
                    if hbProject.hbFont1.fileUrl == nil {
                        setHBFont(fromUrl: url, asMainFont: true)
                    }
                    else {
                        setHBFont(fromUrl: url, asMainFont: false)
                    }
                }
            }
        }
        
        return true
    }
    
    // Set font file from a url, dragged and dropped or opened via (+) button
    func setHBFont(fromUrl: URL, asMainFont: Bool) {
        if asMainFont {
            hbProject.hbFont1.fontSize = 40
            hbProject.hbFont1.setFontFile(filePath: fromUrl.path)
            // Save the bookmark in document for future use
            document.projectData.fontFile1Bookmark = securityScopedBookmark(ofUrl: fromUrl)
        }
        else {
            hbProject.hbFont1.fontSize = 40
            hbProject.hbFont2.setFontFile(filePath: fromUrl.path)
            // Save the bookmark in document for future use
            document.projectData.fontFile2Bookmark = securityScopedBookmark(ofUrl: fromUrl)
        }
        clusterViewModel.currentScript = hbProject.hbFont1.selectedScript
        glyphItems.removeAll()
        hbGridItems.removeAll()
        hbProject.refresh()
        refreshGridItems()
    }
    
    func securityScopedBookmark(ofUrl: URL) -> Data {
        // Create a security scoped bookmark so we can open this again in the future
        let bookmarkData = try! ofUrl.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        return bookmarkData
    }
    
    func updateFontBookmark(mainFont: Bool) {
        if mainFont {
            if hbProject.hbFont1.fileUrl == nil && document.projectData.fontFile1Bookmark != nil {
                    document.projectData.fontFile1Bookmark = nil
            } else if hbProject.hbFont1.fileUrl != nil && document.projectData.fontFile1Bookmark == nil {
                document.projectData.fontFile1Bookmark = securityScopedBookmark(ofUrl: hbProject.hbFont1.fileUrl!)
            }
        }
        else {
            if hbProject.hbFont2.fileUrl == nil && document.projectData.fontFile2Bookmark != nil {
                    document.projectData.fontFile2Bookmark = nil
            } else if hbProject.hbFont2.fileUrl != nil && document.projectData.fontFile2Bookmark == nil {
                document.projectData.fontFile2Bookmark = securityScopedBookmark(ofUrl: hbProject.hbFont2.fileUrl!)
            }
        }
        
        hbProject.refresh()
    }
    
    func doubleClicked(clickedItem: HBGridItem) {
        showGlyphView = tappedItem == clickedItem
    }
    
    func refreshGridItems() {
        // Reset the tapped item
        tappedItem = HBGridItem()
        
        // Perform the refresh in another thread
        DispatchQueue.main.async {
            if gridViewOptions.currentTab == HBGridViewTab.FontsTab {
                refreshGlyphsInFonts()
            }
            else if gridViewOptions.currentTab == HBGridViewTab.ClustersTab {
                refreshClusters()
            }
            else if gridViewOptions.currentTab == HBGridViewTab.WordsTab {
                refreshWordsFromList()
            }
            else {
                refreshNumbers()
            }
        }
    }
    
    func glyphViewDismissed() {
        showGlyphView = false
    }
    
    // MARK: ----- Refresh Glyphs in Font

    func refreshGlyphsInFonts() {
        print("Refreshing items in Font tab")
        hbGridItems.removeAll()
        if hbProject.hbFont1.available {
            // If we already have the data backed up, use it instead of recreating
            if glyphItems.count > 0 && glyphItems.count == hbProject.hbFont1.glyphCount && !gridViewOptions.showUnicodesOnly {
                hbGridItems = glyphItems
                maxCellWidth = glyphCellWidth
                return
            }
            
            glyphItems.removeAll()
            
            // Easier to get glyphname in a CGFont
            let cgFont = CTFontCopyGraphicsFont(hbProject.hbFont1.ctFont!, nil)
            
            let fontData1   = hbProject.hbFont1.getHBFontData()
            let fontData2   = hbProject.hbFont2.getHBFontData()
            let cgFont2     = hbProject.hbFont2.available ? CTFontCopyGraphicsFont(hbProject.hbFont2.ctFont!, nil) : nil
    
            // Get the glyph information and set the width of the widest glyph as the maxCellWidth
            glyphCellWidth  = 100
            let scale       = (Hibizcus.FontScale / (2048/hbProject.hbFont1.metrics.upem)) * (192/40)
            // Let's run this in the background as it can take very long for large fonts
            DispatchQueue.global(qos: .background).async {
                for i in 0 ..< hbProject.hbFont1.glyphCount {
                    let gId         = CGGlyph(i)
                    let gName       = cgFont.name(for: gId)! as String
                    let fd1         = fontData1?.getGlyfData(forGlyphName: gName) ?? nil
                    let adv         = fd1?.width ?? 0
                    var width       = CGFloat(Float(adv)/scale)
                    var wordItem    = HBGridItem(type:HBGridItemItemType.Glyph, text: "")
                    
                    // Getting data from fontData will allow more comparisons other then just the width of the glyph.
                    // For that, I need to be able to open and read the font file (thorough otfcc). For systems fonts,
                    // I can't read the TTFs. I can use CTFontGetOpticalBoundsForGlyphs instead.
                    if fd1 == nil {
                        var cgGlyphs = [CGGlyph(gId), CGGlyph(0)]
                        var opticalRect = [CGRect(x: 0, y: 0, width: 0, height: 0), CGRect(x: 0, y: 0, width: 0, height: 0)]
                        let ro = CTFontGetOpticalBoundsForGlyphs(hbProject.hbFont1.ctFont!, &cgGlyphs, &opticalRect, 1, 0)
                        width = ro.width
                    }
                    
                    wordItem.glyphIds[0]    = gId
                    wordItem.width[0]       = width
                    wordItem.label          = gName
                    wordItem.uniLabel       = hbProject.hbFont1.unicodeLabelForGlyphId(glyph: gId)
                    
                    if gridViewOptions.showUnicodesOnly && wordItem.uniLabel == "" {
                        // We can ignore this item
                        continue
                    }
                    
                    var widthDiff   = false
                    var glyfDiff    = false
                    
                    if hbProject.hbFont2.available {
                        let gId2    = cgFont2?.getGlyphWithGlyphName(name: gName as CFString)
                        if (fontData2 != nil) {
                            let fd2     = fontData2?.getGlyfData(forGlyphName: gName) ?? nil
                            glyfDiff    = fd1?.glyf != fd2?.glyf
                            wordItem.glyphIds[1] = gId2 != nil ? CGGlyph(gId2!) : kCGFontIndexInvalid
                            let adv2    = fd2?.width ?? 0
                            wordItem.width[1] = CGFloat(Float(adv2)/scale)
                            widthDiff   = abs(width - wordItem.width[1]) > 0.01
                        }
                        else if gId2 != nil {
                            // This is a system font, we only compare width
                            var cgGlyphs = [CGGlyph(gId2!), CGGlyph(0)]
                            var opticalRect = [CGRect(x: 0, y: 0, width: 0, height: 0), CGRect(x: 0, y: 0, width: 0, height: 0)]
                            let ro = CTFontGetOpticalBoundsForGlyphs(hbProject.hbFont2.ctFont!, &cgGlyphs, &opticalRect, 1, 0)
                            widthDiff = abs(width - ro.width) > 0.01
                        }
                    }
                    
                    wordItem.diffGlyf   = glyfDiff
                    wordItem.diffWidth  = widthDiff
                    glyphCellWidth = max(width, glyphCellWidth)
                    DispatchQueue.main.async {
                        hbGridItems.append(wordItem)
                        glyphItems.append(wordItem)
                        maxCellWidth = glyphCellWidth
                    }
                }
            }
        }
        
        return
    }
    
    // MARK: ----- Refresh Clusters

    func refreshClusters() {
        print("Refreshing items in Clusters tab")
        hbGridItems.removeAll()
        var maxWidth: CGFloat = 100 //maxCellWidth
        
        // This will be used to compare glyf data
        let fontData1   = hbProject.hbFont1.getHBFontData()
        let fontData2   = hbProject.hbFont2.getHBFontData()
        
        for base in clusterViewModel.baseStrings {
            var baseEx = base
            // do we need to add nukta
            if clusterViewModel.addNukta {
                baseEx += clusterViewModel.nukta
            }
            // do we add sub conso?
            if clusterViewModel.selectedSubConsonant != "None" {
                if clusterViewModel.selectedSubConsonant == "Reph" ||
                    clusterViewModel.selectedSubConsonant == "Repha" ||
                    clusterViewModel.selectedSubConsonant == "Repaya" ||
                    clusterViewModel.selectedSubConsonant == "Ra Initial" {
                    baseEx = clusterViewModel.subConsonantString + baseEx
                }
                else {
                    baseEx += clusterViewModel.subConsonantString
                }
            }
            // do we have a vowel selected?
            if clusterViewModel.selectedVowelSign.count > 0 {
                baseEx += clusterViewModel.selectedVowelSign
            }
            // Other signs?
            if clusterViewModel.selectedOtherSign.count > 0 {
                baseEx += clusterViewModel.selectedOtherSign
            }
            
            // Get the width
            let sld1 = hbProject.hbFont1.getStringLayoutData(forText: baseEx)
            maxWidth = max(sld1.width, maxWidth)

            let colorGlyphs = gridViewOptions.colorGlyphs && !hbProject.hbFont2.available
            
            var item = HBGridItem(type:HBGridItemItemType.Cluster, text: baseEx, colorGlyphs: colorGlyphs)
            item.width[0] = (sld1.width)
            
            // If there are two fonts, see if we have a diff
            if hbProject.hbFont2.available {
                //if baseEx == "ल्क्य" || baseEx == "क़" || baseEx == "கா" {
                //    print("Debugging \(baseEx)")
                //}
                let sld2 = hbProject.hbFont2.getStringLayoutData(forText: baseEx)
                item.width[1] = sld2.width
                item.diffWidth = abs(item.width[1] - item.width[0]) > 0.01
                item.diffLayout = !(sld1 == sld2)
                for hbGlyph in sld1.hbGlyphs {
                    let fd1 = fontData1?.getGlyfData(forGlyphName: hbGlyph.name) ?? nil
                    let fd2 = fontData2?.getGlyfData(forGlyphName: hbGlyph.name) ?? nil
                    if fd1 != nil && fd2 != nil {
                        if fd1!.glyf != fd2!.glyf {
                            item.diffGlyf = true
                            break
                        }
                    }
                }
            }
            hbGridItems.append(item)
        }
        minCellWidth = CGFloat(Double(maxWidth) * 1.1)
        maxCellWidth = CGFloat(Double(maxWidth) * 1.1)
    }
    
    
    // MARK: ----- Refresh Words from List
    
    func refreshWordsFromList() {
        print("Refreshing items in Words tab")
        print ("I need to load word data for \(hbProject.hbFont1.selectedScript)-\(hbProject.hbFont1.selectedLanguage)")
         
        // Handle script names w more than a word
        var script = hbProject.hbFont1.selectedScript.hasPrefix("Odia") ? "odia" : hbProject.hbFont1.selectedScript.lowercased()
        script = hbProject.hbFont1.selectedScript.hasPrefix("Meitei Mayek") ? "meeteimayek" : script
        
        // Get the language name, if it's specified as default
        var language = hbProject.hbFont1.selectedLanguage.lowercased()
        if language == "default" {
            language = defaultLanguage(forScript: script).lowercased()
        }
        
        let filename = script + "_" + language
        if let filepath = Bundle.main.path(forResource: filename, ofType: "txt") {
            gridViewOptions.wordlistAvailable = true
            // Get groups - for searches that involve letters instead of unicodes
            var groups = ""
            for letter in theText {
                if groups.count > 0 {
                    groups += "|"
                }
                groups += "(\(letter))"
            }
            
            do {
                let contents = try String(contentsOfFile: filepath)
                // Default pattern is to look for strings that contain theText
                // TODO: Contain this to a max of 4 chars before and after?
                var pattern = "\\b(?=\\w*(\(theText)))\\w+\\b"
                switch gridViewOptions.matchOption {
                case WordSearchOptions.string.rawValue:
                    print("") // This is the default, nothing to do
                case WordSearchOptions.anyLetter.rawValue:
                    pattern = "\\b(?=\\w*\(groups))\\w+\\b"
                case WordSearchOptions.anyUnicode.rawValue:
                    pattern = "\\b(?=\\w*[\(theText)])\\w+\\b"
                    /*
                case WordSearchOptions.onlyLetters.rawValue:
                    // TODO: Figure out how to search for this
                    print("NOT IMPLEMENTED") */
                case WordSearchOptions.onlyUnicodes.rawValue:
                    pattern = "\\b[\(theText)]+\\b(?![,])"
                default:
                    print("") // Nothing to do here either
                }
                
                let results = matches(regex: pattern, in: contents)
                                
                if results.count > 0 {
                    selectWords(fromArray: results, defWordLen: 5)
                }

            } catch {
                print("Could not load contents of file: \(filepath)")
                hbGridItems.removeAll()
            }
        } else {
            print("The text file \(filename) can't be found in the bundle")
            hbGridItems.removeAll()
            gridViewOptions.wordlistAvailable = false
        }
    }
    
    func matches( regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            
            // Limit to 2000 results
            let limit = results.count >= 1000 ? 1000 : results.count
            let returns = results[0..<limit]
            return returns.map {
                String(text[Range($0.range, in: text)!])
            }
            
            // This one returns all matches
            //return results.map {
            //    String(text[Range($0.range, in: text)!])
            //}
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    func selectWords(fromArray: [String], defWordLen: Int) {
        let attributes: [NSAttributedString.Key : Any] = [
            .font: hbProject.hbFont1.ctFont!
        ]
        
        // This will be used to compare glyf data. We need to have the ttf file
        // for this as we are not extracing glyf data from system fonts.
        var fontData1: HBFontData?
        var fontData2: HBFontData?
        if hbProject.hbFont2.fileUrl != nil {
            fontData1 = hbProject.hbFont1.getHBFontData()
            fontData2 = hbProject.hbFont2.getHBFontData()
        }
        
        var maxWidth: CGFloat = 0
        
        // Set the flag so the UI will show the spinner
        gridViewOptions.runningComparisons = true
        
        // This is a long comparison, run it in the background
        DispatchQueue.global(qos: .background).async {
            var selections = [HBGridItem]()
            for word in fromArray {
                if word.count < max(defWordLen, theText.count * 3) {
                    //print("Word: \(word) has \(word.count) chars vs \(theText.count) chars")
                    let width = max(100, word.size(withAttributes: attributes).width)
                    maxWidth = max(width, maxWidth)
                    var item = HBGridItem(type:HBGridItemItemType.Word, text:word)
                    
                    let sld1 = hbProject.hbFont1.getStringLayoutData(forText: word)
                    item.width[0] = (sld1.width)
                    
                    // If there are two fonts, see if we have a diff
                    if gridViewOptions.compareWordLayout {
                        if hbProject.hbFont2.fileUrl != nil {
                            let sld2 = hbProject.hbFont2.getStringLayoutData(forText: word)
                            item.width[1] = sld2.width
                            item.diffWidth = abs(item.width[1] - item.width[0]) > 0.01
                            item.diffLayout = !(sld1 == sld2)
                            // Compare the glyph data of each glyph
                            for hbGlyph in sld1.hbGlyphs {
                                let fd1 = fontData1!.getGlyfData(forGlyphName: hbGlyph.name)
                                let fd2 = fontData2!.getGlyfData(forGlyphName: hbGlyph.name)
                                if fd1!.glyf != fd2!.glyf {
                                    item.diffGlyf = true
                                    break
                                }
                            }
                        }
                    }
                    
                    // Update a local array
                    selections.append(item)
                    if selections.count > 1000 {
                        break
                    }
                }
            }
            
            // Finally update the actual grid items array in the main tread
            DispatchQueue.main.async {
                hbGridItems = selections
                minCellWidth = CGFloat(Double(maxWidth) * 1.2)
                maxCellWidth = CGFloat(Double(maxWidth) * 1.2)
                gridViewOptions.runningComparisons = false
            }
        }
    }
    
    // MARK: ----- Refresh Numbers
    
    func refreshNumbers() {
        //print ("Refreshing items in Numbers tab")
        //print ("I need to load numeric data for \(hbProject.hbFont1.selectedScript)-\(hbProject.hbFont1.selectedLanguage)")
        //print ("Number of digits to use: \(gridViewOptions.digitsOption)")
        
        let scriptNumbers = clusterViewModel.numbers
        let useLatin = scriptNumbers.count == 0 || hbProject.hbFont1.selectedScript == "Latin" || gridViewOptions.showASCIIDigits
        
        var minValue = 100
        var maxValue = 999
        
        switch gridViewOptions.digitsOption {
        case NumberOfDigits.one.rawValue:
            minValue = 0
            maxValue = 9
        case NumberOfDigits.two.rawValue:
            minValue = 10
            maxValue = 99
        case NumberOfDigits.three.rawValue:
            minValue = 100
            maxValue = 999
        case NumberOfDigits.four.rawValue:
            minValue = 1000
            maxValue = 9999
        case NumberOfDigits.five.rawValue:
            minValue = 10000
            maxValue = 99999
        case NumberOfDigits.six.rawValue:
            minValue = 100000
            maxValue = 999999
        default:
            print("") // Nothing to do here either
        }
        
        let numRange = maxValue - minValue
        let itemCount = numRange < 200 ? numRange : 200
                
        var numArray = [String]()
        
        if itemCount >= 100 {
            for _ in 0 ..< itemCount {
                var number = String(Int.random(in: minValue ... maxValue))
                if gridViewOptions.showThousand || gridViewOptions.showLakh {
                    number = insertComma(inNumber: number, showLakh: gridViewOptions.showLakh, showThousand: gridViewOptions.showThousand )
                }
                if !useLatin {
                    number = translateNumber(asciiNumber: number, scriptNumbers: scriptNumbers)
                }
                numArray.append( number )
            }
        }
        else {
            for i in minValue ... minValue+itemCount {
                var number = String(i)
                if !useLatin {
                    number = translateNumber(asciiNumber: number, scriptNumbers: scriptNumbers)
                }
                numArray.append( number )
            }
        }
        
        selectWords(fromArray: numArray, defWordLen: 10)
    }
    
    
    func updateNumberItems() {
        for i in 0 ..< hbGridItems.count {
            hbGridItems[i].text = insertComma(inNumber: hbGridItems[i].text!,
                                              showLakh: gridViewOptions.showLakh,
                                              showThousand: gridViewOptions.showThousand)
        }
    }
    
    // MARK: ----- helpers
    
    // Json Helper
    func paramsForToolWindow(asJson: Bool, text:String) -> String {
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
        let prjName = projectFileUrl?.lastPathComponent ?? ""

        if asJson {
            let data = [
                "text": text,
                "font1BookMark": bkMk1,
                "font2BookMark": bkMk2,
                "font1Url": f1Url,
                "font2Url": f2Url,
                "font1Script": scrp1,
                "font2Script": scrp2,
                "font1Chars": chrs1,
                "font2Chars": chrs2,
                "project" : prjName
            ]
            
            let dataInJson = try! JSONEncoder().encode(data)
            return String(data: dataInJson, encoding: .utf8)!
        }
        
        // Otherwise, return URL Params
        let etext = text.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let echrs1 = chrs1.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let echrs2 = chrs2.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let params = "text=\(etext)&font1BookMark=\(bkMk1)&font2BookMark=\(bkMk2)&font1Url=\(f1Url)&font2Url=\(f2Url)&project=\(prjName)" +
                "&font1Script=\(scrp1)&font2Script=\(scrp2)&font1Chars=\(echrs1)&font2Chars=\(echrs2)"
        return params
    }
}

// Toggle Left Sidebar
func toggleLeftSidebar() {
    NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
}
