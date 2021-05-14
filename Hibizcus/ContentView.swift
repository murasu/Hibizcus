//
//  ContentView.swift
//  Hibiscus
//
//  Created by Muthu Nedumaran on 22/3/21.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: HibiscusDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(HibiscusDocument()))
    }
}
