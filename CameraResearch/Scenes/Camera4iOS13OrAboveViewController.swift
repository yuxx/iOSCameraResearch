import UIKit
import AVFoundation
import SwiftUI

@available(iOS 13.0, *)
final class Camera4iOS13OrAboveViewController: UIViewController {
    var captureSession: AVCaptureSession = AVCaptureSession()

    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?

    var previewLayer: AVCaptureVideoPreviewLayer?

    let shootingButton: UIButton = UIButton()
    let closeButton: UIButton = UIButton()

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
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        super.viewDidLoad()

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

    private var availableDeviceTypes4Camera: [AVCaptureDevice.DeviceType] {
        [
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
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: availableDeviceTypes4Camera, mediaType: .video, position: .unspecified)
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
                debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                    + "photoOut is nil"
                    , level: .err)
                return
            }
            photoOut.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])])
            if captureSession.canAddOutput(photoOut) {
                captureSession.addOutput(photoOut)
            }
        } catch {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                + "\nerror: \(error)"
                , level: .err)
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
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        setupShootingButton()
        setupCloseButton()
        // todo:
    }
    private func setupShootingButton() {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        shootingButton.backgroundColor = .white
        shootingButton.addTarget(self, action: #selector(shooting), for: .touchDown)
        view.addSubview(shootingButton)

        shootingButton.translatesAutoresizingMaskIntoConstraints = false
        let centeringGuide = shootingButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let bottomGuide = shootingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 20)
        let widthGuide = shootingButton.widthAnchor.constraint(equalToConstant: 60)
        let heightGuide = shootingButton.heightAnchor.constraint(equalToConstant: 60)
        NSLayoutConstraint.activate([centeringGuide, bottomGuide, widthGuide, heightGuide])
    }

    @objc private func shooting(_ sender: UIButton) {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        // todo:
    }

    private func setupCloseButton() {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        closeButton.setImage(UIImage(systemName: "multiply")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeCamera), for: .touchUpInside)
        view.addSubview(closeButton)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        let topGuide = closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        let trailingGuide = closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        NSLayoutConstraint.activate([topGuide, trailingGuide])
    }

    @objc func closeCamera(_ sender: UIButton) {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        dismiss(animated: true)
    }
}

@available(iOS 13.0, *)
final class Camera4iOS13OrAboveViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Camera4iOS13OrAboveViewController {
        Camera4iOS13OrAboveViewController()
    }

    func updateUIViewController(_ uiViewController: Camera4iOS13OrAboveViewController, context: Context) {
    }

    typealias UIViewControllerType = Camera4iOS13OrAboveViewController
}
