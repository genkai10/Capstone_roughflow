import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: CameraView
        var previewLayer: AVCaptureVideoPreviewLayer?

        init(parent: CameraView) {
            self.parent = parent
        }

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            // Handle the sample buffer if needed (for future prediction use)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()

        // Create a capture session to capture video from the camera
        let session = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("No camera found.")
            return viewController
        }

        let videoDeviceInput: AVCaptureDeviceInput
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Error setting up video input: \(error)")
            return viewController
        }

        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
        } else {
            print("Could not add video input.")
            return viewController
        }

        // Create a preview layer to display the camera feed
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoPreviewLayer.frame = viewController.view.bounds
        videoPreviewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(videoPreviewLayer)

        // Store the previewLayer in the Coordinator
        context.coordinator.previewLayer = videoPreviewLayer

        // Start the session
        session.startRunning()

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Update the camera preview layer (if necessary)
        if let previewLayer = context.coordinator.previewLayer {
            previewLayer.frame = uiViewController.view.bounds
        }
    }
}

