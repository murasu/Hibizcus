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
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.help) {
                Button("Hibizcus Help") {
                    NSWorkspace.shared.open(URL(string: "https://hibizcus.com")!)
                }
            }
            // This places the menu item under the view top level command
            CommandGroup(before: .appVisibility) { //} .toolbar) {
                Button("Application Support Directory") {
                    let fileManager = FileManager.default
                    let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask) as [NSURL]
                    if let applicationSupportURL = urls.first {
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: applicationSupportURL.path!)
                    }
                }
            }
            // To add my own menu - for later
            /*
            CommandMenu("My Own Top Menu") {
                Button("My Sub Menu Item") { print("User selected my submenu") }
                    .keyboardShortcut("S")
            }
            */
        }
            
        WindowGroup("StringViewer") {
            // activate existing window if exists
            HBStringView()
                .handlesExternalEvents(preferring: Set(arrayLiteral: "stringview"), allowing: Set(arrayLiteral: "stringview"))
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "stringview"))  // create new window if one doesn't exist
        
        WindowGroup("TraceViewer") {
            HBTraceView()
                .handlesExternalEvents(preferring: Set(arrayLiteral: "traceview"), allowing: Set(arrayLiteral: "traceview"))
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "traceview"))
        
        Settings {
            HibizcusSettings()
        }
    }
}
