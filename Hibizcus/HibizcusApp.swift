//
//  HibizcusApp.swift
//
//  Created by Muthu Nedumaran on 22/3/21.
//

import SwiftUI
import Combine

class HBProject: ObservableObject {
    @Published var projectName      = ""
    @Published var hbFont1          = HBFont(filePath: "", fontSize: 40)
    @Published var hbFont2          = HBFont(filePath: "", fontSize: 40)
    @Published var hbGridViewText   = ""
    @Published var hbStringViewText = ""
    @Published var hbTraceViewText  = ""
    // Holds the last updated timestamp. Used to force change the value for UI updates
    @Published var lastUpdated      = ""
    
    func refresh() {
        self.lastUpdated = NSDate().timeIntervalSince1970.debugDescription
    }
}

@main
struct HibizcusApp: App {
    
    //@StateObject var hbProject = HBProject()
    
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
            TraceView()
                .handlesExternalEvents(preferring: Set(arrayLiteral: "traceview"), allowing: Set(arrayLiteral: "traceview" /*"*"*/))
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "traceview"))
    }
}
