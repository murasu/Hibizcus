//
//  HBGridSidebarClusterViewModel.swift
//
//  Created by Muthu Nedumaran on 10/3/21.
//

import Combine
import SwiftUI
import AppKit

class HBGridSidebarClusterViewModel: ObservableObject {
    
    var didChange = PassthroughSubject<Void, Never>()

    @Published var currentScript: String = "" {
        didSet {
            print("script in SidebarClusterViewModel is now \(currentScript)")
            initClusterData()
            didChange.send()
        }
    }
    
    // These are used in the UI only
    @Published var errorMessage         = ""
    @Published var baseItems            = RadioItems()
    @Published var subConsonants        = RadioItems()
    @Published var vowelSignParts       = 1
    @Published var selectedBase         = "Vowels" {
        didSet {
            setSelectedBase()
            didChange.send()
        }
    }
    @Published var selectedSubConsonant = "None" {
        didSet {
            setSelectedSubConsonant()
            didChange.send()
        }
    }
    @Published var selectedVowelSign    = ""
    @Published var selectedOtherSign    = ""
    @Published var addNukta             = false
    @Published var nukta                = ""
    @Published var vowelSigns           = [String]()
    @Published var otherSigns           = [String]()
    @Published var numbers              = [String]()
    @Published var usesLakh             = true
    // These will be populated based on selection
    @Published var baseStrings          = [String]()
    @Published var subConsonantString   = "" 
    @Published var justLoadedFromFile   = false
    
    // This will be set by cluster entry editor
    @Published var otherBases           = [String](){
        didSet {
            setSelectedBase()
            didChange.send()
        }
    }
    
    private func clearClusterData() {
        errorMessage            = ""
        baseItems               = RadioItems()
        subConsonants           = RadioItems()
        selectedVowelSign       = ""
        selectedOtherSign       = ""
        addNukta                = false
        nukta                   = ""
        vowelSigns              = [String]()
        otherSigns              = [String]()
        vowelSignParts          = 1
        baseStrings             = [String]()
        subConsonantString      = ""//[String]()
    }
    
    private func initClusterData() {
        clearClusterData()
        
        var errorMessage    = ""
        
        if currentScript.count == 0 {
            errorMessage = "Script is not set1!"
        }
        else {
            let loadResults = loadClusterData()
            errorMessage = loadResults.error
            let dictionary = loadResults.dict
            
            // I should not send this to the main thread as grid update
            // is done before this is processed in the queue
            //DispatchQueue.main.async {
                if errorMessage.count > 0 {
                    self.errorMessage = "Can't load cluster data for \(self.currentScript): \(errorMessage)"
                }
                else {
                    if dictionary["BaseNames"] == nil {
                        self.errorMessage = "Invalid cluster data in file for script \(self.currentScript)"
                    }
                    else {
                        print(">>> Loading cluster data for \(self.currentScript)!")
                        self.errorMessage            = ""
                        self.baseItems.labels        = dictionary["BaseNames"] ?? [String]()
                        self.nukta                   = dictionary["Nukta"]?[0]  ?? ""
                        self.subConsonants.labels    = dictionary["SubConsonantNames"] ?? [String]()
                        self.vowelSigns              = dictionary["Vowel Signs"]  ?? [String]()
                        self.otherSigns              = dictionary["Other Signs"]  ?? [String]()
                        self.numbers                 = dictionary["Numbers"]  ?? [String]()
                        let usesLakhSetting          = dictionary["UsesLakh"]?[0] ?? "true"
                        self.usesLakh                = usesLakhSetting.lowercased() == "true"
                        // Max parts in a vowel sign
                        self.vowelSignParts          = Int(dictionary["Hibizcus"]![3]) ?? 0
                        // Currently selected base
                        self.baseStrings             = dictionary[self.selectedBase] ?? [String]()
                        if dictionary[self.selectedSubConsonant] != nil && self.selectedSubConsonant.count > 0 {
                            self.subConsonantString      = dictionary[self.selectedSubConsonant]![0]
                        }
                        self.justLoadedFromFile      = true // to initiate a refresh
                    }
                }
            //}
        }
    }
    
    func setSelectedBase() {
        // TODO: Handle this better
        if selectedBase == "Other Bases" {
            baseStrings = otherBases // [UserDefaults.standard.string(forKey: "ToDoCustomBase") ?? ""]
            return
        }
        
        let loadResults = loadClusterData()
        if loadResults.error.count == 0  {
            let dictionary = loadResults.dict
            baseStrings = dictionary[selectedBase]!
        }
    }
    
    func setSelectedSubConsonant() {
        let loadResults = loadClusterData()
        if loadResults.error.count == 0  {
            let dictionary = loadResults.dict
            subConsonantString = dictionary[selectedSubConsonant]![0]
        }
    }
    
    func loadClusterData() -> (dict:[String: [String]], error: String) {
        // Initialise local vars
        var errorMessage    = ""
        var clusterFile     = "cluster_\(currentScript.lowercased())"
        
        var jsonString      = ""
        var dictionary      = [String: [String]]()
        
        // Exception - Odia
        if clusterFile == "cluster_odia (formerly oriya)" {
            clusterFile = "cluster_odia"
        }
        
        // Exception - Meetei Mayek
        if clusterFile.hasPrefix("cluster_meitei mayek") {
            clusterFile = "cluster_meeteimayek"
        }
        
        print("Initializing cluster view model from: \(clusterFile). Nukta is \(nukta)")
        // Read the json string from file
        do {
            if let fileURL = Bundle.main.url(forResource: clusterFile, withExtension: "json") {
                
                jsonString = try String(contentsOf: fileURL, encoding: .utf8)
                
                // Parse the json into dictionary
                do {
                    dictionary = try JSONSerialization.jsonObject(with: Data(jsonString.utf8), options: []) as? [String: [String]] ?? [String: [String]]()
                }
                catch {
                    errorMessage = error.localizedDescription
                    print("Error while reading cluster data: \(errorMessage)")
                }
            }
            else {
                //errorMessage = "File \(clusterFile).json not found!"
                errorMessage = "Data not available."
                print("Error: \(errorMessage)")
            }
        }
        catch {
            errorMessage = error.localizedDescription
            print("Error while reading json file from \(clusterFile): \(errorMessage)")
        }
        
        return (dict:dictionary, error: errorMessage)
    }
    
    // Called by cluster entry editor when user sets other bases
    func setOtherBases(oBases: String) {
        if oBases.count > 0 {
            let oBasesArray = oBases.components(separatedBy: ",")
            // trim each element
            otherBases = oBasesArray.map { $0.trimmingCharacters(in: .whitespaces) }
        }
    }
}

