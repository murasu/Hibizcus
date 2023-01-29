//
//  HibizcusSettings.swift
//  Hibizcus
//
//  Created by Muthu Nedumaran on 28/1/23.
//

import SwiftUI
import Combine

struct HibizcusSettings: View {
    
    @State var maxWords: String = String(maxWordCountPreference())

    var body: some View {
        HStack {
            Text("Max items in Words tab (capped at 10k):")
            TextField("", text: $maxWords)
                .onReceive(Just(maxWords)) { newValue in
                    let filtered = newValue.filter { "0123456789".contains($0) }
                    if filtered != newValue {
                        self.maxWords = filtered
                    }
                    // Don't allow blank
                    if self.maxWords == "" {
                        self.maxWords = "1000" // the default
                    }
                    // Cap it at 10,000
                    if Int(maxWords)! > 10000 {
                        self.maxWords = "10000"
                    }
                    //print("New Value is \(maxWords)")
                    UserDefaults.standard.set(Int(maxWords), forKey: Hibizcus.Key.MaxWordCount)
                }
        }
        .frame(width: 600, height: 150)
        .padding(20)
    }
}

func maxWordCountPreference() -> Int {
    return UserDefaults.standard.integer(forKey: Hibizcus.Key.MaxWordCount) == 0 ? 1000 : UserDefaults.standard.integer(forKey: Hibizcus.Key.MaxWordCount)
}
