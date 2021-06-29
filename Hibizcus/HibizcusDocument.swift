//
//  HibizcusDocument.swift
//
//  Created by Muthu Nedumaran on 22/3/21.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let hibizcusProject = UTType(exportedAs: "com.murasu.hibizcus.project")
}

struct HibizcusProjectData: Codable {
    var searchText  = ""
    var fontFile1Bookmark: Data?
    var fontFile2Bookmark: Data?
    // Also allow system fonts, picked up by
    // string or characters in that script
    var systemFont1Script: String?
    var systemFont2Script: String?
    var systemFont1Chars: String?
    var systemFont2Chars: String?
    // String that stores 'other bases' used in clusters tab
    var otherBases: String?
}

struct HibizcusDocument: FileDocument, Codable {
    var projectData: HibizcusProjectData

    init(p: HibizcusProjectData = HibizcusProjectData()) {
        self.projectData = p
    }

    static var readableContentTypes: [UTType] { [.hibizcusProject] }

    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents!
        self = try JSONDecoder().decode(Self.self, from: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(self)
        return FileWrapper(regularFileWithContents: data)
    }
}
