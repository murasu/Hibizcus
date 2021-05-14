//
//  LoadAnimation.swift
//
//  Created by Muthu Nedumaran on 19/4/21.
//

import SwiftUI

struct LoadAnimation: View {
 
    @State private var animating = false
 
    var body: some View {
        ZStack {
 
            Circle()
                .stroke(Color(.green), lineWidth: 3)
                .frame(width: 20, height: 20)
 
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(Color.red, lineWidth: 3)
                .frame(width: 20, height: 20)
                .rotationEffect(Angle(degrees: animating ? 360 : 0))
                .animation(Animation.linear(duration: 0.5).repeatForever(autoreverses: false))
                .onAppear() {
                    self.animating = true
            }
        }
    }
}
