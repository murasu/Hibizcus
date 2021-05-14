//
//  RadioGroup.swift
//
//  Created by Muthu Nedumaran on 7/3/21.
//

import Combine
import SwiftUI
import AppKit

class RadioItems: ObservableObject {
    @Published var labels = [String]()
}

struct RadioButton: View {
    let id: String
    let label: String
    let size: CGFloat
    let textSize: CGFloat
    let marked:Bool
    let callback: (String)->()
    
    init(
        id: String,
        label:String,
        size: CGFloat = 16,
        textSize: CGFloat = 12,
        isMarked: Bool = false,
        callback: @escaping (String)->()
        ) {
        self.id = id
        self.label = label
        self.size = size
        self.textSize = textSize
        self.marked = isMarked
        self.callback = callback
    }
    
    var body: some View {
        Button(action:{
            self.callback(self.id)
        }) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: self.marked ? "largecircle.fill.circle" : "circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: self.size, height: self.size)
                    .foregroundColor(Color.primary)
                Text(label)
                    .font(Font.system(size: textSize))
                Spacer()
            }
            .foregroundColor(Color.primary)
            .padding(.leading, 20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RadioGroup: View {
    let callback: (String) -> ()
    @State var selection: String = ""
    
    @ObservedObject var options: RadioItems
    
    var body: some View {
        VStack {
            ForEach (options.labels, id: \.self) { label in
                RadioButton(id: label, label: label, isMarked: label==selection, callback: groupCallback)
            }
        }
    }
    
    func groupCallback(id: String) {
        selection = id
        callback(id)
    }
}

