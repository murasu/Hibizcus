//
//  HBFontScriptSelectionView.swift
//  Hibizcus
//
//  Created by Muthu Nedumaran on 16/6/21.
//

import Cocoa
import Combine
import SwiftUI

struct Script: Identifiable, Equatable, Hashable, Codable {
    var id = UUID()
    var scriptName: String
    var scriptChar: String
}

struct HBFontScriptSelectionView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var hbFont:HBFont
    @State var scripts = [Script]()
    
    var body: some View {
        VStack {
            Text("Select script for system font")
                .font(.title)
                .padding(15)
            List( scripts ) { script in
                HStack {
                    Text(script.scriptName)
                    Spacer()
                    Text(script.scriptChar)
                }
            }
            .frame(width: 250, height: 400, alignment: .center)
            .padding(.horizontal, 10)
            .padding(.top, 0)
            .padding(.bottom, 10)
            HStack {
                Button {
                    // Save the selected langauges to userdefaults
                    saveSelections()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Load system font")
                }
            }
            .padding(.bottom, 20)
        }
        .onAppear() {
            if scripts.count == 0 {
                if let filepath = Bundle.main.path(forResource: "supported_scripts", ofType: "txt") {
                    do {
                        let contents = try String(contentsOfFile: filepath)
                        let lines = contents.components(separatedBy: .newlines)
                        for line in lines {
                            if line.count > 1 {
                                let comps = line.components(separatedBy: ",")
                                scripts.append(Script(scriptName: comps[0], scriptChar: comps[1]))
                            }
                        }
                        print("Supported scripts: \(scripts)")
                    } catch {
                        print("Content of supported_scripts could not be loaded")
                    }
                } else {
                    print("File supported_scripts.txt could not be found")
                }
            }
        }
    }
    
    func saveSelections() {
        var selections = [Language]()
        for language in hbFont.supportedLanguages {
            if language.selected {
                selections.append(language)
            }
        }
        let selectionData = try! JSONEncoder().encode(selections)
        UserDefaults.standard.setValue(selectionData, forKey: Hibizcus.Key.SelectedLanguages)
        
        // Take this opportunity to sort the array
        hbFont.supportedLanguages.sort { (lhs, rhs) -> Bool in
            return String(!rhs.selected) + rhs.langName > String(!lhs.selected) + lhs.langName
        }
        
        // Update the filtered languages for the Picker
        hbFont.updateFilteredLanguages()
    }
}

/*
struct HBLanguageRow: View {
    var language: Language
    var highlighted: Bool
    
    var body: some View {
        VStack {
            HStack {
                if language.selected {
                    Text( Image(systemName: "checkmark") )
                        .font(.system(size: 14, design: .monospaced))
                        .frame(width: 12, height: 20, alignment: .leading)
                        .padding(.trailing, 10)
                } else {
                    Text(" ")
                        .font(.system(size: 14, design: .monospaced))
                        .frame(width: 15, height: 20, alignment: .leading)
                        .padding(.trailing, 10)
                }
                Divider()
                Text(language.langName)
                    .font(.system(size: 14, design: .monospaced))
                    .frame(width: 200, height: 20, alignment: .leading)
                Spacer()
                Divider()
                Text(language.langId)
                    .font(.system(size: 14, design: .monospaced))
                    .frame(width: 35, height: 20, alignment: .leading)
            }
            .background(highlighted ? Color.blue : .clear)
            // Make the entire HStack tappable
            .contentShape(Rectangle())
            Divider()
        }
    }
}

struct HBClearButton: View {
    var highlighted: Bool
    
    var body: some View {
        HStack {
            (Text(Image(systemName: "xmark")) + Text(" Clear selections"))
                .font(.system(size: 14, design: .monospaced))
                .padding(15)
                .background(highlighted ? Color.red : .clear)
            Spacer()
        }
        .padding(10)
    }
}
*/
