//
//  HBClusterEntryEditor.swift
//
//  Created by Muthu Nedumaran on 9/3/21.
//

import Cocoa
import Combine
import SwiftUI

struct HBClusterEntryEditor: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var hbProject: HBProject

    @Binding var document: HibizcusDocument
    @ObservedObject var viewModel: HBGridSidebarClusterViewModel
    @State var entryName: String
    @State var entryData: String
    @State var script: String
    @State var language: String
    @State var key: String
    // TODO: To be implemented.
    
    var body: some View {
        VStack {
            Text(entryName)
                .font(.title)
                .padding(15)
            
            Text("Enter the base strings for this script,\nseperated by comma:")
                .font(.caption)
            
            TextEditor(text: $entryData)
                .frame(width: 200, height: 200, alignment: .center)
                .border(Color.primary.opacity(0.2))
                .font(.title2)
                .padding(0)
                        
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Save") {
                    document.projectData.otherBases = entryData
                    viewModel.setOtherBases(oBases: entryData)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding(.vertical, 10)
        }
        .padding(.horizontal, 10)
        .padding(.top, 0)
        .padding(.bottom, 10)
    }
}
