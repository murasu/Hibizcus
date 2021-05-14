//
//  PickerGrid.swift
//
//  Created by Muthu Nedumaran on 7/3/21.
//

import Combine
import SwiftUI
import AppKit


struct PickerGrid: View {
    var title: String
    var items: [String]
    var maxParts: Int
    @State var selected: String
    @State var touched = ""
    let callback: (String) -> ()
        
    let columns = [
        GridItem(.adaptive(minimum: 20))
    ]
    
    var body: some View {
        HStack {
            Text(title)
                .padding(.leading, 20)
                .padding(.top, 10)
            Spacer()
        }
        LazyVGrid(columns: [GridItem(.adaptive(minimum: CGFloat(20*maxParts)))], spacing: 2) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.title2)
                    .padding(3)
                    .border(colorForItem(item: item), width: 1)
                    .padding(.vertical, 10)
                    .gesture(DragGesture(minimumDistance: 0.0, coordinateSpace: .global)
                                .onChanged { _ in
                                    // touch down
                                    touched = item
                                }
                                .onEnded { _ in
                                    // touch up
                                    touched = ""
                                    selected = selected == item ? "" : item
                                    itemPicked(id: selected)
                                }
                    )
            }
        }
        .padding(.horizontal, 20)
    }
    
    func colorForItem(item: String) -> Color {
        if item == selected {
            return Color.primary
        }
        else if item == touched {
            return Color.primary.opacity(0.5)
        }
        
        return Color.clear
    }
    
    func borderWidthForItem(item: String) -> Int {
        if item == selected || item == touched {
            return 1
        }
        
        return 0
    }
    
    func itemPicked(id: String) {
        selected = id
        callback(id)
    }
}
