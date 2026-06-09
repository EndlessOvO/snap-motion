import SwiftUI

struct SnapPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SnapTypography.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(SnapColors.coral)
        .controlSize(.large)
    }
}

struct SnapProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(SnapColors.ink.opacity(0.12))
                Capsule()
                    .fill(SnapColors.mint)
                    .frame(width: proxy.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 10)
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}
