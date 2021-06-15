//
//  GlyphsViewRepresentable.swift
//  OpenRecentDocument
//
//  Created by Muthu Nedumaran on 25/2/21.
//

import Combine
import SwiftUI

struct HBTraceRowViewRepresentable: NSViewRepresentable {
    
    typealias NSViewType = HBTraceRowView

    var tvLogItem: TVLogItem
    var ctFont:CTFont
    @ObservedObject var viewOptions:HBTraceViewOptions

    func makeNSView(context: Context) -> HBTraceRowView {
        let traceRowView = HBTraceRowView()
        // Set defaults
        traceRowView.tvLogItem = tvLogItem
        traceRowView.ctFont = ctFont
        traceRowView.viewOptions = viewOptions
        return traceRowView
    }
    
    func updateNSView(_ nsView: HBTraceRowView, context: Context) {
        //print("Update called: in TraceRowViewRepresentable")
        nsView.tvLogItem = tvLogItem
        nsView.ctFont = ctFont
        nsView.viewOptions = viewOptions
    }
}
