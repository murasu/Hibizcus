//
//  HibizcusApp.swift
//
//  Created by Muthu Nedumaran on 22/3/21.
//

import SwiftUI
import Combine

@main
struct HibizcusApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: HibizcusDocument()) { file in
            HBGridView(document: file.$document, projectFileUrl: file.fileURL)
        }
        
        WindowGroup("StringViewer") {
            // activate existing window if exists
            HBStringView()
                .handlesExternalEvents(preferring: Set(arrayLiteral: "stringview"), allowing: Set(arrayLiteral: "stringview" /*"*"*/))
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "stringview"))  // create new window if one doesn't exist
        
        WindowGroup("TraceViewer") {
            HBTraceView()
                .handlesExternalEvents(preferring: Set(arrayLiteral: "traceview"), allowing: Set(arrayLiteral: "traceview" /*"*"*/))
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "traceview"))
    }
}
