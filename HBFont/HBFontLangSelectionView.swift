//
//  HBFontLangSelectionView.swift
//
//  Created by Muthu Nedumaran on 27/2/21.
//

import Cocoa
import Combine
import SwiftUI

struct HBFontLangSelectionView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var hbFont:HBFont
    @State var highlighted:Language? = nil
    @State var clearHighlighted:Bool = false
    
    var body: some View {
        VStack {
            Text("Select Languages")
                .font(.title)
                .padding(15)
            /*
            HBClearButton(highlighted: clearHighlighted)
                .gesture(DragGesture(minimumDistance: 0.0, coordinateSpace: .global)
                    .onChanged { _ in
                        clearHighlighted = true
                    }
                    .onEnded { _ in
                        clearHighlighted = false
                        clearSelections()
                    }
                ) */
            List(hbFont.supportedLanguages /*supportedLanguages.languages*/) { language in
                // We don't allow default to be deselected
                //if language.langName != Hibizcus.Shaper.DefaultLanguage {
                    HBLanguageRow(language: language, highlighted: highlighted==language)
                        // Use drag gesture so we can handle touch down and touch up
                        .gesture(DragGesture(minimumDistance: 0.0, coordinateSpace: .global)
                                .onChanged { _ in
                                    // touch down
                                    highlighted = language
                                }
                                .onEnded { _ in
                                    // touch up
                                    let index = hbFont.supportedLanguages.firstIndex(of: language)
                                    hbFont.supportedLanguages[index!].selected.toggle()
                                }
                        )
                //}
            }
            .frame(width: 400, height: 400, alignment: .center)
            .padding(.horizontal, 10)
            .padding(.top, 0)
            .padding(.bottom, 10)
            HStack {
                Button {
                    undoChanges()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Cancel")
                }
                Button {
                    // Save the selected langauges to userdefaults
                    saveSelections()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Save")
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    func clearSelections() {
        for i in 0 ..< hbFont.supportedLanguages.count {
            hbFont.supportedLanguages[i].selected = false
        }
        highlighted = nil
    }
    
    func undoChanges() {
        // TODO: Figure a way to cancel all the changes
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
