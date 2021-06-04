//
//  HBGridSidebarCluster.swift
//
//  Created by Muthu Nedumaran on 6/3/21.
//

import Combine
import SwiftUI
import AppKit

struct HBGridSidebarCluster: View {
    @EnvironmentObject var hbProject: HBProject
    @ObservedObject var viewModel: HBGridSidebarClusterViewModel
    
    @State var showingEditor = false
    
    var body: some View {
        if viewModel.errorMessage.count == 0 {
            ScrollView([.vertical], showsIndicators: true) {
                HStack {
                    ZStack {
                        VStack(alignment: .leading) {
                            Text("Bases:")
                                .padding(.leading, 20)
                            RadioGroup(callback: { selected in
                                print("Selected options is: \(selected)")
                                viewModel.selectedBase = selected
                            }, selection: viewModel.selectedBase, options: viewModel.baseItems)
                        }
                        .padding(.vertical, 15)
                        VStack(alignment: .leading) {
                            Spacer()
                            HStack {
                                Spacer()
                                Button {
                                    showingEditor.toggle()
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .padding(.trailing, 10)
                                .padding(.bottom, 15)
                                .help("Edit custom bases")
                                .sheet(isPresented: $showingEditor, onDismiss: editingDone) {
                                    let currentEntry = UserDefaults.standard.string(forKey: "ToDoCustomBase") ?? ""
                                    HBClusterEntryEditor(entryName: "Other Bases", entryData: currentEntry, script: "", language: "", key: "")
                                }
                            }
                        }
                    }
                    Spacer()
                }
                
                Divider()
                
                // Nukta
                if viewModel.nukta.count > 0 {
                    HStack {
                        VStack(alignment: .leading) {
                            Toggle("Nukta", isOn:$viewModel.addNukta)
                                .padding(.top, 10)
                                .padding(.leading, 20)
                                .padding(.bottom, 15)
                        }
                        Spacer()
                    }
                    
                    Divider()
                }
                
                // Sub Consonants
                HStack {
                    VStack(alignment: .leading) {
                        Text("Sub-consonants:")
                            .padding(.leading, 20)
                        RadioGroup(callback: { selected in
                            print("Selected options is: \(selected)")
                            viewModel.selectedSubConsonant = selected
                        }, selection: viewModel.selectedSubConsonant, options: viewModel.subConsonants)
                    }
                    .padding(.vertical, 15)
                    Spacer()
                }
                
                Divider()
                
                PickerGrid(title: "Vowel Signs:", items: viewModel.vowelSigns, maxParts: viewModel.vowelSignParts, selected: "") { picked in
                    //print("Selected vowel sign: \(picked)")
                    viewModel.selectedVowelSign = picked
                }
                
                Divider()
                
                PickerGrid(title: "Other Signs:", items: viewModel.otherSigns, maxParts: viewModel.vowelSignParts, selected: "") { picked in
                    //print("Selected other sign: \(picked)")
                    viewModel.selectedOtherSign = picked
                }
            }
        }
        else {
            Text(viewModel.errorMessage)
                .foregroundColor(.red)
                .padding()
        }
    }
    
    func editingDone() {
        
    }
}
