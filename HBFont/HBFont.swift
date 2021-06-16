//
//  HBFont.swift
//
//  Created by Muthu Nedumaran on 27/2/21.
//

import Cocoa
import Combine
import SwiftUI

struct Language: Identifiable, Equatable, Hashable, Codable {
    var id = UUID()
    var langName: String
    var langId: String
    var selected: Bool
}

struct HBGlyph: Identifiable, Equatable, Hashable {
    var id                  = UUID()        // To conform to identifiable protocol
    var name                = ""            // Glyph name
    var glyphId: UInt16     = 0             // Glyph ID == CGGlyph (= UInt16)
    var unicode             = ""            // Unicode value in Hex : Eg: 0B85
    var character           = ""            // The character as a string
    var color               = Color.black   // Default glyph color
    
    static func == (lhs: HBGlyph, rhs: HBGlyph) -> Bool {
        return lhs.id == rhs.id
    }
}

class StringLayoutData: Equatable, ObservableObject {
    @Published var hbGlyphs         = [HBGlyph]()
    @Published var anchors          = [[CGPoint]]()
    @Published var positions        = [CGPoint]()
    @Published var width: CGFloat   = 0.0
    @Published var count            = 0
    
    // Only compares layout diff: number of glyphs, order of glyphs and positions of glyphs
    // Does not care about overall width, though there is a chance for this to be diff if positions differ
    static func == (lhs: StringLayoutData, rhs: StringLayoutData) -> Bool {
        var isEqual = false
        
        let countMatch  = lhs.hbGlyphs.count == rhs.hbGlyphs.count
        
        // To match the glyph, we only compare names and unicodes. Ignore the glyph ID as it can change
        var glyphsMatch = countMatch // assume
        if countMatch {
            for i in 0 ..< lhs.hbGlyphs.count {
                if !(lhs.hbGlyphs[i].name == rhs.hbGlyphs[i].name && lhs.hbGlyphs[i].unicode == rhs.hbGlyphs[i].unicode) {
                    glyphsMatch = false
                    break
                }
            }
        }
        
        let positionsMatch  = lhs.positions.count == rhs.positions.count
        // If there is still no diff, compare the position data of each glyph
        if positionsMatch {
            for i in 0..<lhs.positions.count {
                if abs(lhs.positions[i].x - rhs.positions[i].x) > 0.01 || abs(lhs.positions[i].y - rhs.positions[i].y) > 0.01 {
                    isEqual = false
                    break
                }
            }
        }
        print("   Count match \(countMatch) Glyf match \(glyphsMatch), Positions match \(positionsMatch)")
        isEqual = countMatch && glyphsMatch && positionsMatch

        return isEqual
    }
    
    func replace(with: StringLayoutData) {
        self.hbGlyphs       = with.hbGlyphs
        self.anchors        = with.anchors
        self.positions      = with.positions
        self.width          = with.width
        self.count          = with.count
    }
}

class SupportedLanguages: ObservableObject {
    @Published var languages = [Language]()
    @Published var selectedLanguage = Hibizcus.Shaper.DefaultLanguageName
}

enum BookmarkedFontOpenError: Error {
    case noFontSet
    case startAccessingFailed
}

class HBFont: ObservableObject {
    @Published var available                        = false // Flag to indicate if this font is available for use in the tools
    @Published var fileUrl: URL?
    @Published var fontSize: Int
    @Published var ctFont: CTFont?
    @Published var displayName: String              = "" {
        didSet { self.objectWillChange.send() }
    }
    @Published var version:String                   = "" {
        didSet { self.objectWillChange.send() }
    }
    @Published var metrics: FontMetrics             = FontMetrics()
    @Published var glyphCount: Int                  = 0
    @Published var supportedScripts: [String]       = [String]()
    @Published var supportedLanguages: [Language]   = [Language]()
    @Published var filteredLanguages: [String]      = [String]()
    @Published var shapers: [String]                = [Hibizcus.Shaper.CoreText, Hibizcus.Shaper.Harfbuzz]
    @Published var fileWatcher                      = HBFileWatcher()
    @Published var selectedLanguage: String         = Hibizcus.Shaper.DefaultLanguageName {
        didSet { self.objectWillChange.send() }
    }
    @Published var selectedScript: String           = Hibizcus.Shaper.DefaultLanguageName {
        didSet { self.objectWillChange.send() }
    }
    @Published var selectedShaper: String           = Hibizcus.Shaper.CoreText {
        didSet { self.objectWillChange.send() }
    }
    
    var anyCancellable: AnyCancellable?             = nil

    private var anchorsByGlyphName: [String: [CGPoint]]?
    private var unicodeByGlyphId: [CGGlyph : UnicodeScalar]?
    
    // TODO: Call the C function directly instead of going through a ObjC++/C++ bridge
    // Used only by the hb shaper
    private var bridge = HibizcusCppBridge()
    
    // Use characters in this string when loading a system font
    var charsInScript = ""
    
    // Init with filename
    init(filePath: String, fontSize: Int) {
        if filePath.count > 0  {
            self.fileUrl = URL(fileURLWithPath: filePath)
        } else {
            self.fileUrl = nil
        }
        self.fontSize = fontSize
        createCTFont()
        extractFontInfo()
        fileWatcher.stopWatchingForChanges()
        
        if filePath.count > 0 {
            fileWatcher.watchForChangesInFileAtUrl(fileUrl: URL(fileURLWithPath: filePath))
        }
        
        // Notify change when fileWatcher, which is a nested ObservableObject, changes
        anyCancellable = fileWatcher.objectWillChange.sink { [weak self] (_) in
            //if self!.fileUrl != nil {
            //    print("fileWatcher: sending objectWillChange for file \(self!.fileUrl!)")
            //}
            self?.objectWillChange.send()
        }
        
    }
    
    // Init system font for character(s) in given string
    func loadFontFor(script: String, fontSize: Int, charsInScript: String) {
        self.fontSize = fontSize
        self.charsInScript = charsInScript
        createCTFont()
        extractFontInfo()
        if available {
            // Only the selected script and default
            self.supportedScripts = [script, Hibizcus.Shaper.DefaultLanguageName]
            self.selectedScript = script
        }
    }
    
    // Init with scoped bookmark and watch for changes
    func loadFontWith(fontBookmark: Data, fontSize: Int) {
        do {
            var isStale = false
                    
            fileUrl = try URL(resolvingBookmarkData: fontBookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            let didStart = fileUrl!.startAccessingSecurityScopedResource()
            guard didStart else {
                throw BookmarkedFontOpenError.startAccessingFailed
            }
            
            // Create CTFont
            // TODO: reuse createCTFont func here!
            let fontData = NSData(contentsOf: fileUrl!) //as CFData
            if fontData != nil {
                let descriptor = CTFontManagerCreateFontDescriptorFromData(fontData! as CFData)
                self.ctFont = CTFontCreateWithFontDescriptor(descriptor!, CGFloat(fontSize), nil)
                if ( ctFont != nil ) {
                    print("New cfont created: \(String(describing: ctFont))")
                    displayName = CTFontCopyDisplayName(ctFont!) as String
                    version = CTFontCopyName(ctFont!, kCTFontVersionNameKey)! as String
                    // If we have a file, we support both shapers
                    self.shapers = [Hibizcus.Shaper.CoreText, Hibizcus.Shaper.Harfbuzz]
                    available = true
                }
                
                fileWatcher.stopWatchingForChanges()
                fileWatcher.watchForChangesInFileAtUrl(fileUrl: fileUrl!)
            }
        }
        catch {
            // Create from system font
            fileUrl = nil
            ctFont = CTFontCreateUIFontForLanguage(CTFontUIFontType.label, CGFloat(fontSize), nil)!
        }
        
        self.fontSize = fontSize
        supportedLanguages.removeAll()
        supportedScripts.removeAll()
        extractFontInfo()
    }
    
    deinit {
        if fileUrl != nil {
            fileUrl!.stopAccessingSecurityScopedResource()
        }
    }
    
    func setFontFile(filePath: String) {
        // Clear
        self.fileUrl = nil
        self.charsInScript = ""
        self.selectedScript = ""
        self.available = false
        supportedLanguages.removeAll()
        supportedScripts.removeAll()
        // Create
        if filePath.count > 0 {
            self.fileUrl = URL(fileURLWithPath: filePath)
            // If we have a file, we support both shapers
            self.shapers = [Hibizcus.Shaper.CoreText, Hibizcus.Shaper.Harfbuzz]
        } 
        createCTFont()
        extractFontInfo()
        fileWatcher.stopWatchingForChanges()
        if filePath.count > 0 {
            fileWatcher.watchForChangesInFileAtUrl(fileUrl: URL(fileURLWithPath: filePath))
        }
        // Notify change when fileWatcher, which is a nested ObservableObject, changes
        anyCancellable = fileWatcher.objectWillChange.sink { [weak self] (_) in
            //if self!.fileUrl != nil {
            //    print("fileWatcher: sending objectWillChange for file \(self!.fileUrl!)")
            //}
            self?.objectWillChange.send()
        }
    }
    
    func reloadFont() {
        supportedLanguages.removeAll()
        supportedScripts.removeAll()
        createCTFont()
        extractFontInfo()
    }
    
    private func extractFontInfo() {
        getFontMetrics()
        // Get the supported languages first
        getSupportedLanguages()
        // Get the supported scripts, it'll also have
        // language properties
        getSupportedScripts()
        // Update the language selection filter
        updateFilteredLanguages()
        // Glyph ID to Unicode map
        createGlyphToUnicodeMap()
        // Get the anchors
        getAnchors()
    }
    
    private func createCTFont() {
        displayName = ""
        version     = ""
        ctFont      = nil
        
        if ( fileUrl != nil ) {
            do {
                let fontData = try NSData(contentsOf: fileUrl!) as CFData
                let descriptor = CTFontManagerCreateFontDescriptorFromData(fontData)
                ctFont = CTFontCreateWithFontDescriptor(descriptor!, CGFloat(fontSize), nil)
                available = true
            }
            catch {
                print("GlyphView: Can't create ctFont from file: \(fileUrl!.absoluteString). Error \(error.localizedDescription)")
            }
        }
        
        if ctFont == nil {
            // Create from system font
            ctFont = CTFontCreateUIFontForLanguage(CTFontUIFontType.label, CGFloat(fontSize), nil)!
            if charsInScript != "" {
                ctFont = CTFontCreateForString(ctFont!, charsInScript as CFString, CFRange(location: 0, length: 1))
                // System font can't use Harfbuzz as we can't open the file
                self.shapers = [Hibizcus.Shaper.CoreText]
                available = true
            }
        }
        
        if ( ctFont != nil ) {
            print("New cfont created: \(String(describing: ctFont))")
            displayName = CTFontCopyDisplayName(ctFont!) as String
            version = CTFontCopyName(ctFont!, kCTFontVersionNameKey)! as String
        }
    }
    
    private func getFontMetrics() {
        // Scaled font-ascent metric
        metrics.ascent      = ctFont == nil ? 0 : Float(CTFontGetAscent(ctFont!))
        // Scaled font-descent metric
        metrics.descent     = ctFont == nil ? 0 : Float(CTFontGetDescent(ctFont!))
        // Leading
        metrics.leading     = ctFont == nil ? 0 : Float(CTFontGetLeading(ctFont!))
        // Cap Height
        metrics.capHeight   = ctFont == nil ? 0 : Float(CTFontGetCapHeight(ctFont!))
        // x height
        metrics.xHeight     = ctFont == nil ? 0 : Float(CTFontGetXHeight(ctFont!))
        // Underline
        metrics.underline   = ctFont == nil ? 0 : Float(CTFontGetUnderlinePosition(ctFont!))
        // Underline thickness
        metrics.ulThickness = ctFont == nil ? 0 : Float(CTFontGetUnderlineThickness(ctFont!))
        // UPEM
        metrics.upem        = ctFont == nil ? 0 : Float(CTFontGetUnitsPerEm(ctFont!))
        // Also get the glyph count
        glyphCount          = ctFont == nil ? 0 : CTFontGetGlyphCount(ctFont!)
    }
    
    private func getSupportedScripts() {
        // There are no APIs for getting the supported scripts through CT.
        // Only getting supported languages is available.
        // Let's get it from the GSUB table via otfcc
        
        if fileUrl == nil {
            return
        }
        
        fileUrl!.withUnsafeFileSystemRepresentation { cStr in
            
            // Get the unicodes in the font and collect the scripts they represent
            // Added 2012-05-12
            bridge.hbSetFontFilePath(cStr)
            let unicodes = bridge.hbCollectUnicodes() as NSArray as! [UInt32]
            //print("Unicodes: \(unicodes)")
            
            supportedScripts = scriptsFromUnicodes(unicodes: unicodes)
            //print("Scripts: \(scripts)")
            
            if supportedScripts.count > 0 {
                selectedScript = supportedScripts[0]
            }

            // Below is the earlier method, where I collected script & language
            // info from OT Tables. Keeping is to collect the language tags used
            // in these tables
            // TODO: Evaluate if this is really necessary!
            
            // Call our C function to get the json data for the entire font
            let jsonData = String(cString: get_data_as_json_from_font_file(cStr))
            
            let size = jsonData.count
            print("Json file of length \(size) fetched!")
            
            do {
                // Decode data to a Dictionary<String, Any> object
                guard let dictionary = try JSONSerialization.jsonObject(with: Data(jsonData.utf8), options: []) as? [String: Any] else {
                    print("Could not cast JSON content as a Dictionary<String, Any>")
                    return
                }
                // Get supported scripts
                let tables = ["GPOS", "GSUB"]
                for table in tables {
                    // Print the lookups in the GPOS table
                    let otTable = dictionary[table] as? Dictionary<String, AnyObject>
                    if otTable != nil {
                        let languages = otTable!["languages"] as? Dictionary<String, AnyObject>
                        let scriptTags = OTScriptTags()
                        let langTags = OTLanguageTags()
                        for language in languages!.keys {
                            let idx = language.firstIndex(of: "_")
                            if idx != nil {
                                let scriptCode = String(language.prefix(upTo: idx!))
                                // Remove v.2 in case it's present
                                let script = scriptTags.scripts[scriptCode]?.replacingOccurrences(of: " v.2", with: "")
                                // This may not be necessary
                                if script != nil && !supportedScripts.contains(script!) {
                                    supportedScripts.append(script!)
                                }
                                
                                let nextIndex = language.index(idx!, offsetBy: 1)
                                let langCode = String(language.suffix(from: nextIndex)).trimmingCharacters(in: .whitespacesAndNewlines)
                                let langName = langTags.languages[langCode]
                                // Add this language to filtered languages
                                if langName != nil {
                                    //print("Adding language \(langName) from \(table) table")
                                    setLanguageAsSelected(langName: langName!)
                                }
                            }
                        }
                    }
                }
            }
            catch {
                print("Error parsig JSON for OT Tables \(error.localizedDescription)")
            }
        }
    }
    
    private func getSupportedLanguages() {
        if ctFont == nil {
            return
        }
        
        let currentLocale = Locale.current as NSLocale
        let langCodes = CTFontCopySupportedLanguages(ctFont!) as! [String]
        let allSelected = langCodes.count <= 10
        for langCode in langCodes {
            let n = currentLocale.displayName(forKey:NSLocale.Key.identifier, value:langCode)
            let l = Language(langName: n!, langId: langCode, selected: allSelected)
            supportedLanguages.append(l)
        }
        // Add the Default language
        let l = Language(langName:"Default", langId: "dflt", selected: true)
        supportedLanguages.append(l)
        // Sort the array
        supportedLanguages.sort { (lhs, rhs) -> Bool in
            return String(!rhs.selected) + rhs.langName > String(!lhs.selected) + lhs.langName
        }
    }
    
    func getHBFontData() -> HBFontData? {
        if fileUrl == nil {
            return nil
        }
        
        var hbFontData: HBFontData?
        
        fileUrl!.withUnsafeFileSystemRepresentation { cStr in
            hbFontData = HBFontData(pathAsCString: cStr!)
        }
        
        return hbFontData
    }
    
    func setLanguageAsSelected(langName:String) {
        for language in supportedLanguages {
            if language.langName == langName {
                let index = supportedLanguages.firstIndex(of: language)
                supportedLanguages[index!].selected = true
            }
        }
    }
    
    func updateFilteredLanguages() {
        // Load previously saved ones
        var savedSelections = [Language]()
        let savedSelectionData = UserDefaults.standard.data(forKey: Hibizcus.Key.SelectedLanguages)
        if savedSelectionData != nil {
            savedSelections = try! JSONDecoder().decode([Language].self, from: savedSelectionData!)
        }
        
        filteredLanguages.removeAll()
        for language in supportedLanguages {
            if language.selected {
                filteredLanguages.append(language.langName)
            }
            else {
                // See if this is in saved selections
                for savedSelection in savedSelections {
                    if savedSelection.langName == language.langName {
                        setLanguageAsSelected(langName: language.langName)
                        filteredLanguages.append(language.langName)
                    }
                }
            }
        }

        filteredLanguages.sort()
    }
    
    func languageCode(forName: String) -> String {
        for language in supportedLanguages {
            if language.langName == forName {
                return language.langId
            }
        }
        
        return ""
    }
    
    // MARK: Unicode Map
    
    // For now, use CoreText to get a mapping of Unicode->Glyph names.
    // 2021-05-12: I can also get the unicode values through Harfbuzz.
    // TODO: Evaluate which one is better
    // Do I to get that through harfbuzz so we take what harfbuzz sees?
    // Taken from here: https://stackoverflow.com/questions/56782339/how-to-get-all-characters-of-the-font-with-ctfontcopycharacterset-in-swift
    private func createGlyphToUnicodeMap() {
        unicodeByGlyphId = [CGGlyph : UnicodeScalar]() // Start with empty map.

        if ctFont == nil {
            return
        }
        
        let charset = CTFontCopyCharacterSet(ctFont!) as CharacterSet
        // Enumerate all Unicode scalar values from the character set:
        for plane: UInt8 in 0...16 where charset.hasMember(inPlane: plane) {
            for unicode in UTF32Char(plane) << 16 ..< UTF32Char(plane + 1) << 16 {
                if let uniChar = UnicodeScalar(unicode), charset.contains(uniChar) {

                    // Get glyph for this `uniChar` ...
                    let utf16 = Array(uniChar.utf16)
                    var glyphs = [CGGlyph](repeating: 0, count: utf16.count)
                    if CTFontGetGlyphsForCharacters(ctFont!, utf16, &glyphs, utf16.count) {
                        // ... and add it to the map.
                        unicodeByGlyphId![glyphs[0]] = uniChar
                    }
                }
            }
        }
    }
    
    func unicodeLabelForGlyphId(glyph:CGGlyph) -> String {
        let v = unicodeByGlyphId![glyph]?.value ?? 0
        if v > 0 {
            return String(format:"%04X",v)
        }
        return ""
    }
    
    // MARK: Anchors
    
    private func getAnchors() {
        anchorsByGlyphName = nil
        let scale = (Hibizcus.FontScale / (2048/metrics.upem)) * (192/Float(fontSize))
        if ctFont != nil && useKerx() {
            anchorsByGlyphName = HBFontAnkrTable().getAnchorPoints(fromFont: ctFont!, scale: scale)
        }
        
        // If we can't use kerx, use GPOS anchors
        if anchorsByGlyphName == nil {
            // Get the OpenType anchors
            if self.fileUrl == nil {
                return
            }
            
            fileUrl!.withUnsafeFileSystemRepresentation { cStr in
                anchorsByGlyphName = AnchorPoints().getAnchorPoints(fromFile: cStr!, useScale:scale)
            }
        }
    }
    
    private func useKerx() -> Bool {
        if ctFont != nil {
            var hasMorx = false; var hasKerx = false
            let tags = CTFontCopyAvailableTables(ctFont!, CTFontTableOptions(rawValue: 0))
            for i in 0 ..< CFArrayGetCount(tags) {
                if CTFontTableTag(uintptr_t(bitPattern: CFArrayGetValueAtIndex(tags, i))) == kCTFontTableMorx {
                    print("Font has morx")
                    hasMorx = true
                }
                if CTFontTableTag(uintptr_t(bitPattern: CFArrayGetValueAtIndex(tags, i))) == kCTFontTableKerx {
                    print("Font has kerx")
                    hasKerx = true
                }
            }
            return hasMorx && hasKerx
        }
    
        return false
    }
    
    // MARK: Shaping functions
    
    func getStringLayoutData(forText: String) -> StringLayoutData {
        var stringLayoutData = StringLayoutData()
        if forText == "" || !available { //} fileUrl == nil {
            return stringLayoutData
        }
        else {
            if selectedShaper == Hibizcus.Shaper.CoreText {
                stringLayoutData = getStringLayoutDataWithCoreText(forText: forText)
            }
            else {
                stringLayoutData = getStringLayoutDataWithHarfbuzz(forText: forText)
            }
        }
        
        return stringLayoutData
    }
    
    private func getStringLayoutDataWithCoreText(forText: String) -> StringLayoutData {
        let stringLayoutData = StringLayoutData()
        
        //print("Getting layout data for \(forText) with \(fileUrl?.lastPathComponent ?? "") using \(selectedShaper)")
        if ctFont == nil {
            print("Font in CT is nil - returning stringLayoutData: \(stringLayoutData)")
            return stringLayoutData
        }
                
        let characters = forText
                
        // Initialise attributed string
        let attributedString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0)!
        CFAttributedStringReplaceString(attributedString, CFRangeMake(0, 0), characters as CFString)
                
        // Assign the characters typed
        CFAttributedStringSetAttribute(attributedString, CFRangeMake(0, CFStringGetLength(characters as CFString)), kCTFontAttributeName, ctFont)

        // Set the language
        if selectedLanguage.count > 0 {
            CFAttributedStringSetAttribute(attributedString, CFRangeMake(0, CFStringGetLength(characters as CFString)), kCTLanguageAttributeName, selectedLanguage as NSString)
        }
                
        let ctline = CTLineCreateWithAttributedString(attributedString)
        let width = CTLineGetBoundsWithOptions(ctline, CTLineBoundsOptions(rawValue: 0)).width
        
        guard let runs = (CTLineGetGlyphRuns(ctline) as [AnyObject]) as? [CTRun] else { return stringLayoutData }
                                
        var hbGlyphs = [HBGlyph]()
        var positions = [CGPoint]()
        var anchors = [[CGPoint]]()
        var colorIndex = 0
        
        var glyphCount = 0
        for run in runs {
            let attributes: NSDictionary = CTRunGetAttributes(run)
            // We get the glyph names from cgfont
            let font = attributes[kCTFontAttributeName as String] as! CTFont
            let cgfont = CTFontCopyGraphicsFont(font, nil)
            // Glyphs in this run
            glyphCount = CTRunGetGlyphCount(run)
            // Font used in this run - can be different from our font since CoreText does font fallback
            let displayNameOfFontUsed = CTFontCopyDisplayName(font) as String
            
            for index in 0..<glyphCount {
                let range = CFRangeMake(index, 1)
                var glyph = CGGlyph()
                if displayNameOfFontUsed != displayName {
                    // Fallback font was used. Ignore!
                    glyph = 0
                } else {
                    CTRunGetGlyphs(run, range, &glyph)
                }
                var unicode:UInt32 = 0
                var glyphName = ""
                var point = CGPoint(
                )
                if glyph == 65535 {
                    glyph = CGGlyph(0)
                    glyphName = "DEL"
                    point = CGPoint(x: 0, y: 0)
                }
                else {
                    glyphName = cgfont.name(for: glyph)! as String
                    CTRunGetPositions(run, range, &point)
                    // Get the Unicode value of this glyph
                    unicode = unicodeByGlyphId![glyph]?.value ?? 0
                }
                
                // Round up to 3 decimal places
                let ys = Double( round(1000*point.y)/1000 )
                let xs = Double( round(1000*point.x)/1000 )
                
                // Get the glyph data for drawing
                positions.append(CGPoint(x: xs, y: ys))
                anchors.append(anchorsByGlyphName?[glyphName] ?? [CGPoint]())
                
                var hbGlyph         = HBGlyph()
                hbGlyph.name        = glyphName
                hbGlyph.glyphId     = glyph
                hbGlyph.character   = String(UnicodeScalar(unicode)!)
                hbGlyph.unicode     = String(format:"%04X", unicode)
                hbGlyph.color       = Color(Hibizcus.colorArray[colorIndex])
                hbGlyphs.append(hbGlyph)
                
                colorIndex += 1
                if colorIndex >= Hibizcus.colorArray.count {
                    colorIndex = 0
                }
            }
        }
        
        stringLayoutData.hbGlyphs   = hbGlyphs
        stringLayoutData.count      = glyphCount
        stringLayoutData.positions  = positions
        stringLayoutData.anchors    = anchors
        stringLayoutData.width      = width

        return stringLayoutData
    }
    
    private func getStringLayoutDataWithHarfbuzz(forText: String) -> StringLayoutData {
        let stringLayoutData = StringLayoutData()
        //print("Getting layout data for \(forText) with \(fileUrl?.lastPathComponent ?? "") using Harfbuzz")
        
        // Shaping is done through harfbuzz. However, drawing is done with CT.
        if ctFont == nil {
            print("Font in CT is nil - returning stringLayoutData: \(stringLayoutData)")
            return stringLayoutData
        }
        
        // Make sure harfbuzz bridge is initialised
        if bridge.hbGetFontDisplayName() == "" {
            // Font not set in shaper
            setFontInHarfbuzz()
            //print("Display name: \(bridge.hbGetFontDisplayName() )")
        }
                
        // Shape the string through harfbuzz and get the output
        let selectedLanguageCode = languageCode(forName: selectedLanguage)
        let jsonString = bridge.hbShapeString(forText, inLanguage: selectedLanguageCode) //self.selectedLanguage)
        let data = Data(jsonString!.utf8)

        var hbResults = [[String: Any]]()
        
        do {
            // make sure this JSON is in the format we expect
            let jsonResponse = try JSONSerialization.jsonObject(with:data, options: [])
            hbResults = jsonResponse as? [[String: Any]] ?? [[String: Any]]()
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
        }
        
        if hbResults.count == 0 {
            return stringLayoutData
        }
        
        // Parse the results
        var hbGlyphs    = [HBGlyph]()
        var positions   = [CGPoint]()
        var anchors     = [[CGPoint]]()
        var glyphCount  = 0
        var colorIndex  = 0
        var num         = 1
        var xPos        = 0.0 as Float
        var resultsString = ""
        
        let scale = (Hibizcus.FontScale / (2048/metrics.upem)) * (192/Float(fontSize))
        
        for hbResult in hbResults {
            if (resultsString.lengthOfBytes(using: .utf8) > 0 ) {
                resultsString = resultsString + "\n"
            }
            resultsString = resultsString + "\(num). \(hbResult["g"] ?? "")"
            
            let glyph = CTFontGetGlyphWithName(ctFont!, hbResult["g"] as! CFString)
            let glyphName = hbResult["g"] as! String
            
            let y = (hbResult["dy"] as! Float) / scale
            let x = xPos + ( (hbResult["dx"] as! Float) / scale )
            
            // Round them up to 3 decimal places
            let ys = Double( round(y*1000)/1000 )
            let xs = Double( round(x*1000)/1000 )
            
            // Get the glyph data for drawing
            positions.append(CGPoint(x: xs, y: ys))
            anchors.append(anchorsByGlyphName?[glyphName] ?? [CGPoint]())
            
            // Unicode value
            let unicode         = unicodeByGlyphId![glyph]?.value ?? 0

            var hbGlyph         = HBGlyph()
            hbGlyph.name        = glyphName
            hbGlyph.glyphId     = glyph
            hbGlyph.character   = String(UnicodeScalar(unicode)!)
            hbGlyph.unicode     = String(format:"%04X", unicode)
            hbGlyph.color       = Color(Hibizcus.colorArray[colorIndex])
            hbGlyphs.append(hbGlyph)
            
            // Update counters and trackers
            xPos        += Float( round(1000*(hbResult["ax"] as! Float)/scale)/1000 )
            num         += 1
            glyphCount  += 1
            colorIndex  += 1
            if colorIndex >= Hibizcus.colorArray.count {
                colorIndex = 0
            }
        }
        
        stringLayoutData.hbGlyphs       = hbGlyphs
        stringLayoutData.positions      = positions
        stringLayoutData.count          = glyphCount
        stringLayoutData.anchors        = anchors
        stringLayoutData.width          = CGFloat(xPos)
        
        return stringLayoutData
    }
    
    private func setFontInHarfbuzz() {
        if fileUrl == nil {
            return
        }
        
        fileUrl!.withUnsafeFileSystemRepresentation { cStr in
            bridge.hbSetFontFilePath(cStr)
            // Get the metics
            let hbMetrics = bridge.hbGetFontMetrics()
            let scale = (Hibizcus.FontScale / (2048/metrics.upem)) * (192/Float(fontSize))
            
            print("HB: xheight = \(hbMetrics!["xHeight"] as! Float) * \(scale)")
            metrics.baseline    = scale * (hbMetrics!["baseline"] as! Float)
            metrics.ascent      = scale * (hbMetrics!["ascender"] as! Float)
            metrics.capHeight   = scale * (hbMetrics!["capheight"] as! Float)
            metrics.descent     = scale * (hbMetrics!["descender"] as! Float)
            metrics.underline   = scale * (hbMetrics!["underlinePos"] as! Float)
            metrics.ulThickness = scale * (hbMetrics!["underlineThickness"] as! Float)
            metrics.xHeight     = scale * (hbMetrics!["baseline"] as! Float)
            metrics.ascent      = scale * (hbMetrics!["xHeight"] as! Float)
            metrics.upem        = (hbMetrics!["upem"] as! Float)
        }
    }
}

extension Double {
    func roundTo(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

