import UIKit
import AVFoundation

@available(iOS 10.0, *)
final class Camera4iOS10OrAboveViewController: UIViewController {
    var captureSession: AVCaptureSession = AVCaptureSession()

    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?

    var previewLayer: AVCaptureVideoPreviewLayer?

    private var _photoOut: Any?
    var photoOut: AVCapturePhotoOutput? {
        get {
            _photoOut as? AVCapturePhotoOutput
        }
        set {
            _photoOut = newValue
        }
    }

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

    private func getAvailableDeviceTypes4Camera() -> [AVCaptureDevice.DeviceType] {
        guard #available(iOS 10.2, *) else {
            return [
                .builtInWideAngleCamera,
                .builtInTelephotoCamera,
            ]
        }
        guard #available(iOS 11.1, *) else {
            return [
                .builtInDualCamera,
                .builtInWideAngleCamera,
                .builtInTelephotoCamera,
            ]
        }
        return [
            .builtInDualCamera,
            .builtInWideAngleCamera,
            .builtInTelephotoCamera,
            .builtInTrueDepthCamera,
        ]
    }

    private func setupAVCaptureDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: getAvailableDeviceTypes4Camera(), mediaType: .video, position: .unspecified)
        let devices = deviceDiscoverySession.devices
        for device in devices {
            switch device.position {
            case .back:
                backCamera = device
            case .front:
                frontCamera = device
            case .unspecified: fallthrough
            @unknown default:
                break
            }
        }
        currentCamera = backCamera
    }

    private func setupCameraIO() {
        do {
            let captureInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.addInput(captureInput)
            photoOut = AVCapturePhotoOutput()
            guard let photoOut = photoOut else {
                print("photoOut is nil")
                return
            }
            if #available(iOS 11.0, *) {
                photoOut.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])])
            }
            if captureSession.canAddOutput(photoOut) {
                captureSession.addOutput(photoOut)
            }
        } catch {
            print("error: \(error)")
        }
    }

    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer?.connection?.videoOrientation = .landscapeLeft
        previewLayer?.frame = view.frame
        view.layer.insertSublayer(previewLayer!, at: 0)
        // todo:
    }

    private func setupCameraView() {
        // todo:
    }
}
