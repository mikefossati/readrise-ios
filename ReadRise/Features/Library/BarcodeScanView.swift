import SwiftUI
import AVFoundation

struct BarcodeScanView: View {
    let onScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var found = false
    @State private var lookingUp = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            BarcodeCameraView { code in
                guard !found else { return }
                found = true
                Task { await lookUp(isbn: code) }
            }
            .ignoresSafeArea()

            // Overlay
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .padding()
                }
                Spacer()

                // Viewfinder guide
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#e8923a"), lineWidth: 3)
                    .frame(width: 260, height: 100)

                Spacer()

                if lookingUp {
                    ProgressView("Looking up book…")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                } else if let err = errorMessage {
                    VStack(spacing: 8) {
                        Text(err)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        Button("Try again") {
                            found = false
                            errorMessage = nil
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: "#e8923a"))
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                } else {
                    Text("Point the camera at a book's barcode")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                }
                Spacer().frame(height: 60)
            }
        }
    }

    private func lookUp(isbn: String) async {
        lookingUp = true
        do {
            let resp: APIResponse<[GoogleBooksVolume]> = try await APIClient.shared.get(
                "/api/books/search",
                queryItems: [URLQueryItem(name: "q", value: "isbn:\(isbn)")]
            )
            if let volume = resp.data.first {
                onAdd(volumeId: volume.id)
            } else {
                errorMessage = "No book found for this barcode."
                found = false
            }
        } catch {
            errorMessage = error.localizedDescription
            found = false
        }
        lookingUp = false
    }

    private func onAdd(volumeId: String) {
        onScanned(volumeId)
        dismiss()
    }
}

// MARK: - Camera view (UIViewRepresentable)

struct BarcodeCameraView: UIViewRepresentable {
    let onScan: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let session = AVCaptureSession()
        context.coordinator.session = session

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return view
        }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
        output.metadataObjectTypes = [.ean13, .ean8, .upce]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = UIScreen.main.bounds
        view.layer.addSublayer(preview)
        context.coordinator.preview = preview

        Task.detached { session.startRunning() }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.preview?.frame = uiView.bounds
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.session?.stopRunning()
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate, @unchecked Sendable {
        var session: AVCaptureSession?
        var preview: AVCaptureVideoPreviewLayer?
        let onScan: (String) -> Void
        private var hasScanned = false

        init(onScan: @escaping (String) -> Void) { self.onScan = onScan }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput objects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard !hasScanned,
                  let object = objects.first as? AVMetadataMachineReadableCodeObject,
                  let code = object.stringValue else { return }
            hasScanned = true
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            onScan(code)
        }
    }
}
