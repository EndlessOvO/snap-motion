import SwiftUI

struct AgeGateView: View {
    let onConfirmed: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Text("Age Confirmation")
                .font(SnapTypography.title)
                .foregroundStyle(SnapColors.ink)
                .multilineTextAlignment(.center)

            Text("Snap Motion is for people 13 and older.")
                .font(SnapTypography.body)
                .foregroundStyle(SnapColors.ink.opacity(0.72))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer()

            SnapPrimaryButton(title: "I am 13 or older") {
                onConfirmed()
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .background(SnapColors.background.ignoresSafeArea())
    }
}
