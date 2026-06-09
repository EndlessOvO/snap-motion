import SwiftUI

struct EnrollmentGuideOverlay: View {
    let progress: Double
    let prompt: String

    var body: some View {
        ZStack {
            Ellipse()
                .strokeBorder(SnapColors.mint, lineWidth: 5)
                .frame(width: 250, height: 330)
                .shadow(color: SnapColors.mint.opacity(0.35), radius: 12)

            VStack {
                Text(prompt)
                    .font(SnapTypography.headline)
                    .foregroundStyle(SnapColors.ink)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.top, 24)

                Spacer()

                SnapProgressBar(progress: progress)
                    .padding(.horizontal, 36)
                    .padding(.bottom, 28)
            }
        }
    }
}
