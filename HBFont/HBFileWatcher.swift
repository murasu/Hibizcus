//
//  HBFileWatcher.swift
//
//  Created by Muthu Nedumaran on 26/3/21.
//

import Cocoa
import Combine
import SwiftUI

class HBFileWatcher: NSObject, NSFilePresenter, ObservableObject {
    var presentedItemURL: URL?
    let presentedItemOperationQueue = OperationQueue()
    @Published var lastDate:Date = Date.init(timeIntervalSinceReferenceDate: .greatestFiniteMagnitude) {
        didSet { self.objectWillChange.send() }
    }
    
    @Published var fontFileChanged: Bool = false {
        didSet { self.objectWillChange.send() }
    }
    
    deinit {
        stopWatchingForChanges()
    }
    
    func watchForChangesInFileAtUrl(fileUrl: URL) {
        stopWatchingForChanges()
        NSFileCoordinator.addFilePresenter(self)
        presentedItemURL = fileUrl
        // Save the current date of the file
        lastDate = fileModificationDate()!
        print("HBFileWatcher: Watching for changes in file: \(fileUrl). Current time: \(lastDate.description)")
    }
    
    func stopWatchingForChanges() {
        fontFileChanged = false
        presentedItemURL = nil
        NSFileCoordinator.removeFilePresenter(self)
    }
    
    func presentedItemDidChange() {
        // File has changed!
        print("HBFileWatcher: Item did change!")
        // We get this callback even if an attribute of the file has changed. We only need
        // to trigger if the file itself has changed. We used to date to determine that
        if /*lastDate == nil ||*/ lastDate != fileModificationDate() {
            DispatchQueue.main.async {
                print("     ==> File at \(String(describing: self.presentedItemURL)) has changed!")
                self.fontFileChanged = true
                // Update the lastDate to the current modification date
                self.lastDate = self.fileModificationDate()!
                // Post a notification
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name(Hibizcus.Messages.FontFileChanged), object: nil)
            }
        }
    }
    
    func fileModificationDate() -> Date? {
        do {
            if ( presentedItemURL != nil ) {
                let attr = try FileManager.default.attributesOfItem(atPath: presentedItemURL!.path)
                return attr[FileAttributeKey.modificationDate] as? Date
            }
        } catch {
            return nil
        }
        return nil
    }
}
