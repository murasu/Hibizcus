//
//  GlyphsViewRepresentable.swift
//  OpenRecentDocument
//
//  Created by Muthu Nedumaran on 25/2/21.
//

import Combine
import SwiftUI

struct TraceRowViewRepresentable: NSViewRepresentable {
    
    typealias NSViewType = TraceRowView

    var tvLogItem: TVLogItem
    var ctFont:CTFont
    @ObservedObject var viewOptions:TraceViewOptions

    func makeNSView(context: Context) -> TraceRowView {
        let traceRowView = TraceRowView()
        // Set defaults
        traceRowView.tvLogItem = tvLogItem
        traceRowView.ctFont = ctFont
        traceRowView.viewOptions = viewOptions
        return traceRowView
    }
    
    func updateNSView(_ nsView: TraceRowView, context: Context) {
        //print("Update called: in TraceRowViewRepresentable")
        nsView.tvLogItem = tvLogItem
        nsView.ctFont = ctFont
        nsView.viewOptions = viewOptions
    }
}
