//
//  LoadingDots.swift
//  contract review
//
//  Created by Claude Code on 2025/10/24.
//

import SwiftUI

struct LoadingDots: View {
    @State private var animationPhase: Int = 0

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.secondary)
                    .opacity(animationPhase == index ? 1.0 : 0.3)
                    .frame(width: 4, height: 4)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

#Preview {
    LoadingDots()
}
