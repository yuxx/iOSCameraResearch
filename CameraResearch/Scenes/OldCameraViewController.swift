import UIKit
import AVFoundation

final class OldCameraViewController: UIViewController {
    var captureSession: AVCaptureSession = AVCaptureSession()

    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?

    var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .green

        setupAVCaptureSession()
        setupAVCaptureDevice()
        setupCameraIO()
        captureSession.startRunning()

        setupPreviewLayer()

        setupCameraView()
    }

    private func setupAVCaptureSession() {
        captureSession.sessionPreset = .photo
    }

    private func setupAVCaptureDevice() {
        let cameras = AVCaptureDevice.devices(for: AVMediaType.video)
        // todo:
    }

    private func setupCameraIO() {
//        do {
//            let captureInput = try AVCaptureDeviceInput(device: currentCamera!)
//            captureSession.addInput(captureInput)
//            photoOut = AVCapturePhotoOutput()
//            guard let photoOut = photoOut else {
//                print("photoOut is nil")
//                return
//            }
//            if #available(iOS 11.0, *) {
//                photoOut.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])])
//            }
//            if captureSession.canAddOutput(photoOut) {
//                captureSession.addOutput(photoOut)
//            }
//        } catch {
//            print("error: \(error)")
//        }
    }

    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer?.connection?.videoOrientation = .landscapeLeft
        previewLayer?.frame = view.frame
        view.layer.insertSublayer(previewLayer!, at: 0)
    }

    private func setupCameraView() {
        // todo:
    }
}
