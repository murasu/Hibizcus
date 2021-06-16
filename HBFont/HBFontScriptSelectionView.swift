//
//  HBFontScriptSelectionView.swift
//  Hibizcus
//
//  Created by Muthu Nedumaran on 16/6/21.
//

import Cocoa
import Combine
import SwiftUI

struct HBScript: Identifiable, Equatable, Hashable, Codable {
    var id = UUID()
    var scriptName: String
    var scriptChar: String
}

struct HBFontScriptSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var hbProject: HBProject

    @ObservedObject var hbFont:HBFont
    @State var scripts = [HBScript]()
    @State var selected = HBScript(scriptName: "", scriptChar: "")
    
    var body: some View {
        VStack {
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }, label: {
                    Image(systemName: "multiply.circle")
                })
                .font(.system(size: 20))
                .padding(.top, 10)
                .padding(.bottom, 0)
                .padding(.horizontal, 10)
                .buttonStyle(PlainButtonStyle())
                Spacer()
                Text("Select Script")
                    .font(.title)
                    .padding(15)
                Spacer()
                Text("")
            }
            
            List( scripts ) { script in
                ScriptRow(scriptName: script.scriptName, scriptChar: script.scriptChar)
                    .contentShape(Rectangle())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(script == selected ? Color.blue : .clear)
                    .gesture(TapGesture(count: 2).onEnded {
                        // UI Update should be done on main thread
                        //DispatchQueue.main.async {
                            loadSelectedSystemFont()
                            presentationMode.wrappedValue.dismiss()
                        //}
                    })
                    .simultaneousGesture(TapGesture().onEnded {
                        DispatchQueue.main.async {
                            selected = script
                        }
                    })
                    .gesture(DragGesture(minimumDistance: 0.0, coordinateSpace: .global)
                                .onChanged { _ in
                                    // touch down
                                    selected = script
                                }
                                .onEnded { _ in
                                    // touch up
                                    //let index = hbFont.supportedLanguages.firstIndex(of: language)
                                    //hbFont.supportedLanguages[index!].selected.toggle()
                                }
                    )
            }
            .frame(width: 250, height: 400, alignment: .center)
            .padding(.horizontal, 10)
            .padding(.top, 0)
            .padding(.bottom, 10)
            
            HStack {
                Button {
                    // Save the selected langauges to userdefaults
                    loadSelectedSystemFont()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Load System Font")
                }
                .disabled(selected.scriptName == "")
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
                                scripts.append(HBScript(scriptName: comps[0], scriptChar: comps[1]))
                            }
                        }
                    } catch {
                        print("Content of supported_scripts could not be loaded")
                    }
                } else {
                    print("File supported_scripts.txt could not be found")
                }
            }
        }
    }
    
    func loadSelectedSystemFont() {
        DispatchQueue.main.async {
            hbFont.loadFontFor(script: selected.scriptName, fontSize: 40, charsInScript: selected.scriptChar)
            hbProject.refresh()
        }
    }
}

struct ScriptRow: View {
    var scriptName: String
    var scriptChar: String
    
    var body: some View {
        HStack {
            Text(scriptName)
            Spacer()
            Text(scriptChar)
        }
    }
}
