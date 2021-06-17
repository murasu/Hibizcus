//
//  HBStringSidebarView.swift
//
//  Created by Muthu Nedumaran on 25/3/21.
//

import Combine
import SwiftUI
import AppKit


struct HBStringSidebarView: View {
    @EnvironmentObject var hbProject: HBProject
    @ObservedObject var stringViewSettings: HBStringViewSettings

    var body: some View {
        ScrollView([.vertical], showsIndicators: true) {
            VStack {
                // Fonts
                HStack (alignment: .top) {
                    VStack(alignment: .leading) {
                        HBSidebarFont()
                    }
                    Spacer()
                }
                .padding(.top, 10)
                
                Divider()
                
                // Script and Language
                HStack (alignment: .top) {
                    VStack(alignment: .leading) {
                        if hbProject.hbFont1.available { //} .fileUrl != nil {
                            HBSidebarLanguage(showDefaultLanguage: false)
                        }
                        else {
                            Text("Load a font to select script and language")
                                .padding(.leading, 20)
                        }
                        //Spacer()
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 10)
                
                Divider()
                
                // StringViewer Display Settings
                if hbProject.hbFont1.available /*fileUrl != nil*/ || hbProject.hbFont2.available { //fileUrl != nil {
                    VStack {
                        VStack (alignment: .leading) {
                            Text("Font size:")
                            Slider(value: $stringViewSettings.fontSize, in: 50...300)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 20)
                        Divider()
                        HStack (alignment: .top) {
                            VStack(alignment: .leading) {
                                Toggle(isOn: $stringViewSettings.showFont1, label: {
                                    Text("Show main font")
                                })
                                Toggle(isOn: $stringViewSettings.showFont2, label: {
                                    Text("Show compare font")
                                })
                                Toggle(isOn: $stringViewSettings.drawMetrics, label: {
                                    Text("Show metrics")
                                })
                                Toggle(isOn: $stringViewSettings.drawUnderLine, label: {
                                    Text("Show underline")
                                })
                                Toggle(isOn: $stringViewSettings.drawBoundingBox, label: {
                                    Text("Show bounding box")
                                })
                                Toggle(isOn: $stringViewSettings.drawAnchors, label: {
                                    Text("Show anchor points")
                                })
                                Toggle(isOn: $stringViewSettings.coloredItems, label: {
                                    Text("Show list in color")
                                })
                            }
                            .padding(.top, 15)
                            .padding(.leading, 20)
                            .padding(.bottom, 20)
                            
                            Spacer()
                        }
                    }
                }
                
                Spacer()
            }
            .frame(minWidth: 230, idealWidth: 260, maxWidth: 300)
        }
    }
}

