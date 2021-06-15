//
//  TraceSidebarView.swift
//
//  Created by Muthu Nedumaran on 27/2/21.
//

import Combine
import SwiftUI
import AppKit


struct HBTraceSideBarView: View {
    @EnvironmentObject var hbProject: HBProject
    @ObservedObject var hbTraceBridge: HBTracerBridge = HBTracerBridge.shared
    @ObservedObject var traceViewData:HBTraceViewOptions
    @State private var showingLanguageSelection = false
    
    var body: some View {
        VStack {
            // Fonts
            HStack (alignment: .top) {
                VStack(alignment: .leading) {
                    HBSidebarFont(showCompareFont: false)
                    Text("Shaper: Harfbuzz")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                Spacer()
            }
            .padding(.top, 15)
            
            Divider()
            
            // Script and Language
            HStack (alignment: .top) {
                VStack(alignment: .leading) {
                    if hbProject.hbFont1.fileUrl != nil {
                        HBSidebarLanguage(showScript: false, showDefaultLanguage: false)
                    }
                    else {
                        Text("Load a font to select script and language")
                            .padding(.leading, 20)
                    }
                    Spacer()
                }
            }
            .padding(.top, 15)
            
            Divider()
            
            HStack(alignment: .top) {
                TraceOptionsView(traceViewData: traceViewData)
                    .padding(.top, 10)
                Spacer()
            }
            .padding(.leading, 15)
            
            Spacer()
        }
        .frame(minWidth: 230, idealWidth: 260, maxWidth: 300)
        .padding(.top, 15)
    }
}

struct TraceOptionsView: View {
    @ObservedObject var traceViewData:HBTraceViewOptions

    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Show full trace", isOn: $traceViewData.showFullTrace)
            Toggle("Show clusters", isOn: $traceViewData.showCluster)
            Toggle("Show glyph names", isOn: $traceViewData.showGlyphNames)
        }
        .padding(.leading, 10)
        .padding(.bottom,  40)
    }
}
