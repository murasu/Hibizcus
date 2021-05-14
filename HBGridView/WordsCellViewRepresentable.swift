//
//  WordsCellViewRepresentable.swift
//  Hibiscus (macOS)
//
//  Created by Muthu Nedumaran on 3/3/21.
//

import Combine
import SwiftUI

struct HBGridCellViewRepresentable: NSViewRepresentable {
    
    typealias NSViewType = HBGridCellView

    var hbFont1:HBFont
    var hbFont2:HBFont
    var wordItem:HBGridItem
    var scale:CGFloat
    @ObservedObject var viewOptions:WordsViewOptions

    func makeNSView(context: Context) -> HBGridCellView {
        let cellView = HBGridCellView()
        // Set defaults
        cellView.hbFont1 = hbFont1
        cellView.hbFont2 = hbFont2
        cellView.gridItem = wordItem
        cellView.viewOptions = viewOptions
        cellView.scale = scale
        return cellView
    }
    
    func updateNSView(_ nsView: HBGridCellView, context: Context) {
        //print("Update called: in TraceRowViewRepresentable")
        nsView.hbFont1 = hbFont1
        nsView.hbFont2 = hbFont2
        nsView.gridItem = wordItem
        nsView.viewOptions = viewOptions
        nsView.scale = scale
    }
}
