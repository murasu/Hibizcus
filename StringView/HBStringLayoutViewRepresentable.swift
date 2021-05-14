//
//  HBStringLayoutViewRepresentable.swift
//
//  Created by Muthu Nedumaran on 25/3/21.
//

import Combine
import SwiftUI

struct HBStringLayoutViewRepresentable: NSViewRepresentable {

    typealias NSViewType = HBStringLayoutView

    @EnvironmentObject var hbProject: HBProject

    var fontSize: Double
    @ObservedObject var slData1: StringLayoutData
    @ObservedObject var slData2: StringLayoutData
    @ObservedObject var stringViewSettings: HBStringViewSettings

    func makeNSView(context: Context) -> HBStringLayoutView {
        let slView = HBStringLayoutView()
        slView.hbFont1      = hbProject.hbFont1
        slView.hbFont2      = hbProject.hbFont2
        slView.slData1      = slData1
        slView.slData2      = slData2
        slView.text         = hbProject.hbStringViewText
        slView.fontSize     = fontSize
        slView.viewSettings = stringViewSettings

        return slView
    }
    
    func updateNSView(_ nsView: HBStringLayoutView, context: Context) {
        //print("Update called: in TraceRowViewRepresentable")
        nsView.hbFont1      = hbProject.hbFont1
        nsView.hbFont2      = hbProject.hbFont2
        nsView.slData1      = slData1
        nsView.slData2      = slData2
        nsView.text         = hbProject.hbStringViewText
        nsView.fontSize     = fontSize
        nsView.viewSettings = stringViewSettings
    }
}
