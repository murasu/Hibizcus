//
//  WordsCellViewRepresentable.swift
//
//  Created by Muthu Nedumaran on 3/3/21.
//

import Combine
import SwiftUI

struct HBGridCellViewRepresentable: NSViewRepresentable {
    
    typealias NSViewType = HBGridCellView

    @EnvironmentObject var hbProject: HBProject
    
    var gridItem: HBGridItem
    var gridViewOptions: HBGridViewOptions
    var scale: CGFloat
    // 2022-07-13
    var showMainFont: Bool
    var showCompareFont: Bool

    func makeNSView(context: Context) -> HBGridCellView {
        let cellView = HBGridCellView()
        // Set defaults
        cellView.hbFont1 = hbProject.hbFont1
        cellView.hbFont2 = hbProject.hbFont2
        cellView.gridItem = gridItem
        cellView.gridViewOptions = gridViewOptions
        cellView.scale = scale
        cellView.showMainFont = showMainFont
        cellView.showCompareFont = showCompareFont
        return cellView
    }
    
    func updateNSView(_ nsView: HBGridCellView, context: Context) {
        nsView.hbFont1 = hbProject.hbFont1
        nsView.hbFont2 = hbProject.hbFont2
        nsView.gridItem = gridItem
        nsView.gridViewOptions = gridViewOptions
        nsView.scale = scale
        nsView.showMainFont = showMainFont
        nsView.showCompareFont = showCompareFont
    }
}
