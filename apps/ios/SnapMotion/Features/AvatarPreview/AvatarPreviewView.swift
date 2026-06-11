import SwiftUI

struct AvatarPreviewView: View {
    @StateObject var viewModel: AvatarPreviewViewModel
    @StateObject private var trackingSession = ARFaceTrackingSession()

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                AvatarSceneView(scene: viewModel.renderer.scene)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(0.78, contentMode: .fit)
                    .background(SnapColors.sky.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.large)
                }
            }
            .padding(.horizontal, 20)

            if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 10) {
                    Text(errorMessage)
                        .font(SnapTypography.caption)
                        .foregroundStyle(SnapColors.coral)
                        .multilineTextAlignment(.center)

                    Button("Reload") {
                        Task {
                            await viewModel.retryLoad()
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(SnapColors.coral)
                }
                .padding(.horizontal, 24)
            }

            controls
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
        }
        .background(SnapColors.background.ignoresSafeArea())
        .task {
            await viewModel.load()
        }
        .onDisappear {
            trackingSession.stop()
            viewModel.stopLiveMode()
        }
        .onChange(of: trackingSession.latestFrame) { _, frame in
            if let frame {
                viewModel.applyLiveFrame(frame)
            }
        }
        .onChange(of: trackingSession.errorMessage) { _, message in
            if message != nil {
                viewModel.stopLiveMode()
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 14) {
            Picker("Preview Mode", selection: liveModeBinding) {
                Text("Manual").tag(false)
                Text("Live").tag(true)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("Preview Mode")

            if viewModel.liveModeStatus == .manual {
                slider(title: "Blink", value: $viewModel.blink)
                slider(title: "Mouth", value: $viewModel.jawOpen)
                slider(title: "Smile", value: $viewModel.smile)
            }

            if viewModel.liveModeStatus == .requestingPermission {
                ProgressView()
            }
        }
        .onChange(of: viewModel.blink) { _, _ in viewModel.applyManualExpression() }
        .onChange(of: viewModel.jawOpen) { _, _ in viewModel.applyManualExpression() }
        .onChange(of: viewModel.smile) { _, _ in viewModel.applyManualExpression() }
    }

    private var liveModeBinding: Binding<Bool> {
        Binding(
            get: { viewModel.liveModeStatus == .live || viewModel.liveModeStatus == .requestingPermission },
            set: { isLive in
                if isLive {
                    Task {
                        if await viewModel.startLiveMode(isFaceTrackingSupported: trackingSession.isSupported) {
                            trackingSession.start()
                        }
                    }
                } else {
                    trackingSession.stop()
                    viewModel.stopLiveMode()
                }
            }
        )
    }

    private func slider(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(SnapTypography.caption)
                .foregroundStyle(SnapColors.ink.opacity(0.75))
            Slider(value: value, in: 0...1)
                .tint(SnapColors.coral)
        }
    }
}
