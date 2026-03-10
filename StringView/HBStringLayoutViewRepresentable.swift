//
//  HBStringLayoutViewRepresentable.swift
//
//  Created by Muthu Nedumaran on 25/3/21.
//

import Combine
import SwiftUI

struct HBStringLayoutViewRepresentable: NSViewRepresentable {

    typealias NSViewType = NSScrollView

    @EnvironmentObject var hbProject: HBProject

    var fontSize: Double
    @ObservedObject var slData1: StringLayoutData
    @ObservedObject var slData2: StringLayoutData
    @ObservedObject var stringViewSettings: HBStringViewSettings

    func makeNSView(context: Context) -> NSScrollView {
        let slView = HBStringLayoutView()
        slView.hbFont1      = hbProject.hbFont1
        slView.hbFont2      = hbProject.hbFont2
        slView.slData1      = slData1
        slView.slData2      = slData2
        slView.text         = hbProject.hbStringViewText
        slView.fontSize     = fontSize
        slView.viewSettings = stringViewSettings

        let scrollView = NSScrollView()
        scrollView.documentView = slView
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let slView = scrollView.documentView as? HBStringLayoutView else { return }
        slView.hbFont1      = hbProject.hbFont1
        slView.hbFont2      = hbProject.hbFont2
        slView.slData1      = slData1
        slView.slData2      = slData2
        slView.text         = hbProject.hbStringViewText
        slView.fontSize     = fontSize
        slView.viewSettings = stringViewSettings
        slView.updateFrameSize(in: scrollView)
    }
}
