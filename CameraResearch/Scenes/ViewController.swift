import UIKit
import AVFoundation

// ref: https://qiita.com/t_okkan/items/f2ba9b7009b49fc2e30a
final class ViewController: UIViewController {
    var captureSession: AVCaptureSession = AVCaptureSession()

    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?

    var previewLayer: AVCaptureVideoPreviewLayer?

//    @available(iOS 10.0, *)
//    var photoOut: AVCapturePhotoOutput?
    private var _photoOut: Any?
    @available(iOS 10.0, *)
    var photoOut: AVCapturePhotoOutput? {
        get {
            _photoOut as? AVCapturePhotoOutput
        }
        set {
            _photoOut = newValue
//            _photoOut = newValue as Any
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupAVCaptureSession()
        setupAVCaptureDevice()
        if #available(iOS 10.0, *) {
            setupCameraIO()
        }
        captureSession.startRunning()

        setupCameraView()
    }

    private func setupAVCaptureSession() {
        captureSession.sessionPreset = .photo
    }

    @available(iOS 10.0, *)
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
        guard #available(iOS 13.0, *) else {
            return [
                .builtInDualCamera,
                .builtInWideAngleCamera,
                .builtInTelephotoCamera,
                .builtInTrueDepthCamera,
            ]
        }
        return [
            .builtInDualCamera,
            .builtInDualWideCamera,
            .builtInTripleCamera,
            .builtInWideAngleCamera,
            .builtInUltraWideCamera,
            .builtInTelephotoCamera,
            .builtInTrueDepthCamera,
        ]
    }

    private func setupAVCaptureDevice() {
        if #available(iOS 10.0, *) {
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
        } else {
            // todo:
            let cameras = AVCaptureDevice.devices(for: AVMediaType.video)
        }
    }

    @available(iOS 10.0, *)
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
    }

    private func setupCameraView() {
        // todo:
    }
}