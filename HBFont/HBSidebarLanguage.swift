//
//  HBSidebarLanguage.swift
//
//  Created by Muthu Nedumaran on 15/4/21.
//

import Combine
import SwiftUI
import AppKit

struct HBSidebarLanguage: View {
    @EnvironmentObject var hbProject: HBProject
    var showScript = true
    @State private  var showingLanguageSelection = false
    @State var showDefaultLanguage: Bool = false

    var body: some View {
        // Pickup the scripts and languages from font1
        if showScript {
            HStack(alignment: .top) {
                Text("Script:")
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 20)
                    .padding(.bottom, 10)
                Spacer()
            }
            Picker("", selection: $hbProject.hbFont1.selectedScript) {
                ForEach(hbProject.hbFont1.scripts, id: \.self) { scriptName in
                    Text(scriptName)
                }
            }
            .padding(.leading, 10)
            .padding(.trailing,15)
            .padding(.bottom,  10)
        }
        
        // Language
        HStack {
            Text("Language:")
                .multilineTextAlignment(.leading)
                .padding(.leading, 20)
                .padding(.bottom, 10)
            Spacer()
            Button {
                showingLanguageSelection.toggle()
            } label: {
                Image(systemName: "doc.badge.gearshape")
            }
            .padding(.trailing, 15)
            .help("Select languages")
            .sheet(isPresented: $showingLanguageSelection, onDismiss: languagesSelected) {
                HBFontLangSelectionView(hbFont: hbProject.hbFont1)
            }
        }
        Picker("", selection: $hbProject.hbFont1.selectedLanguage) {
            ForEach(hbProject.hbFont1.filteredLanguages, id: \.self) { languageName in
                Text(languageName).tag(0)
            }
        }
        .padding(.leading, 10)
        .padding(.trailing,15)
        .padding(.bottom,  10) //40

        if showDefaultLanguage {
            Text(hbProject.hbFont1.selectedLanguage == "Default" ? defaultLanguage(forScript: hbProject.hbFont1.selectedScript) : "")
                .multilineTextAlignment(.leading)
                .padding(.leading, 20)
                .padding(.bottom, 10)
        }
    }
    
    func languagesSelected() {
        print("Languages selected in LanguageSelectionView - may nothing for me to do!")
    }
    
    func scriptChanged() {
        print("Script changed to \(hbProject.hbFont1.selectedScript) in \(self).")
        hbProject.hbFont2.selectedScript = hbProject.hbFont1.selectedScript
        hbProject.refresh()
    }
    
    func languageChanged() {
        print("Language changed to \(hbProject.hbFont1.selectedLanguage).")
        hbProject.hbFont2.selectedLanguage = hbProject.hbFont1.selectedLanguage
        hbProject.refresh()
    }
}





