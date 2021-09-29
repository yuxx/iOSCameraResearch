import UIKit
import AVFoundation
import SwiftUI

protocol PhotoShootDelegate {
    func shooting() -> Void
}

@available(iOS 13.0, *)
final class Camera4iOS13OrAboveViewController: UIViewController, PhotoShootDelegate {
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


    private var shootingButtonWidthGuide: NSLayoutConstraint!
    private var shootingButtonHeightGuide: NSLayoutConstraint!
    private var shootingButtonPortraitOfCenterXGuide: NSLayoutConstraint!
    private var shootingButtonPortraitOfBottomGuide: NSLayoutConstraint!
    private var shootingButtonLandscapeLeftOfCenterYGuide: NSLayoutConstraint!
    private var shootingButtonLandscapeLeftOfRightGuide: NSLayoutConstraint!
    private var shootingButtonLandscapeRightOfCenterYGuide: NSLayoutConstraint!
    private var shootingButtonLandscapeRightOfRightGuide: NSLayoutConstraint!
    private var shootingButtonPortraitUpsideDownOfCenterXGuide: NSLayoutConstraint! // not work on device with notch
    private var shootingButtonPortraitUpsideDownOfBottomGuide: NSLayoutConstraint! // not work on device with notch


    override func viewDidLoad() {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        super.viewDidLoad()

        setupAVCaptureSession()
        setupAVCaptureDevice()
        setupCameraIO()
        captureSession.startRunning()

        setupPreviewLayer()

        setupCameraView()

        // NOTE: 回転時の通知を設定して videoOrientation を変更
        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    @objc private func onOrientationChanged() {
        let orientation = UIDevice.current.orientation
        guard orientation == .portrait || orientation == .landscapeLeft || orientation == .landscapeRight else {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                + "\nupside down is not supported."
                , level: .err)
            return
        }
        guard let connection = previewLayer?.connection else {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                + "\npreviewLayer?.connection is nil"
                , level: .err)
            return
        }
        connection.videoOrientation = Self.getOrientationAsAVCaptureVideoOrientation()

        guard let previewLayer = previewLayer else {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                + "\npreviewLayer is nil"
                , level: .err)
            return
        }
        previewLayer.frame = view.frame
        setupButtonLocation()
    }

    private func setupAVCaptureSession() {
        captureSession.sessionPreset = .photo
    }

    private func setupAVCaptureDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInDualCamera,
                .builtInDualWideCamera,
                .builtInTripleCamera,
                .builtInWideAngleCamera,
                .builtInUltraWideCamera,
                .builtInTelephotoCamera,
                .builtInTrueDepthCamera,
            ],
            mediaType: .video,
            position: .unspecified
        )
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
                    + "\nphotoOut is nil"
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
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        guard let previewLayer = previewLayer else {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                + "\npreviewLayer is nil"
                , level: .err)
            return
        }
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        guard let connection = previewLayer.connection else {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                + "\npreviewLayer.connection is nil"
                , level: .err)
            return
        }
        connection.videoOrientation = Self.getOrientationAsAVCaptureVideoOrientation()
        previewLayer.frame = view.frame
        view.layer.insertSublayer(previewLayer, at: 0)
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
            + "\nconnection.videoOrientation: \(connection.videoOrientation)"
            , level: .dbg)
    }

    static func getOrientationAsAVCaptureVideoOrientation() -> AVCaptureVideoOrientation {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
            + "\nUIDevice.current.orientation: \(UIDevice.current.orientation)"
            , level: .dbg)
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)\tportraitUpsideDown", level: .dbg)
            return .portraitUpsideDown
        case .landscapeLeft:
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)\tlandscapeLeft", level: .dbg)
            // NOTE: カメラ左右はデバイスの向きと逆
            return .landscapeRight
        case .landscapeRight:
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)\tlandscapeRight", level: .dbg)
            // NOTE: カメラ左右はデバイスの向きと逆
            return .landscapeLeft
        default:
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)\tportrait", level: .dbg)
            return .portrait
        }
    }

    private func setupCameraView() {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        setupShootingButton()
        setupCloseButton()
        // todo: その他ボタンや表示
    }
    private func setupShootingButton() {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        shootingButton.backgroundColor = .white
        shootingButton.addTarget(self, action: #selector(shooting(_:)), for: .touchDown)
        view.addSubview(shootingButton)

        shootingButton.translatesAutoresizingMaskIntoConstraints = false
        shootingButtonWidthGuide = shootingButton.widthAnchor.constraint(equalToConstant: 60)
        shootingButtonHeightGuide = shootingButton.heightAnchor.constraint(equalToConstant: 60)

        shootingButtonPortraitOfCenterXGuide = shootingButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        shootingButtonPortraitOfBottomGuide = shootingButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30)

        shootingButtonLandscapeLeftOfCenterYGuide = shootingButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        shootingButtonLandscapeLeftOfRightGuide = shootingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)

        shootingButtonLandscapeRightOfCenterYGuide = shootingButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        shootingButtonLandscapeRightOfRightGuide = shootingButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30)

        shootingButtonPortraitUpsideDownOfCenterXGuide = shootingButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        shootingButtonPortraitUpsideDownOfBottomGuide = shootingButton.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([shootingButtonWidthGuide, shootingButtonHeightGuide])
        setupButtonLocation()
    }

    private func setupButtonLocation() {
        NSLayoutConstraint.deactivate([
            shootingButtonPortraitOfCenterXGuide,
            shootingButtonPortraitOfBottomGuide,

            shootingButtonLandscapeLeftOfCenterYGuide,
            shootingButtonLandscapeLeftOfRightGuide,

            shootingButtonLandscapeRightOfCenterYGuide,
            shootingButtonLandscapeRightOfRightGuide,

            shootingButtonPortraitUpsideDownOfCenterXGuide,
            shootingButtonPortraitUpsideDownOfBottomGuide,
        ])
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)\tportraitUpsideDown", level: .dbg)
            NSLayoutConstraint.activate([
                shootingButtonPortraitUpsideDownOfCenterXGuide,
                shootingButtonPortraitUpsideDownOfBottomGuide,
            ])
        case .landscapeLeft:
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)\tlandscapeLeft", level: .dbg)
            NSLayoutConstraint.activate([
                shootingButtonLandscapeLeftOfCenterYGuide,
                shootingButtonLandscapeLeftOfRightGuide,
            ])
            return
        case .landscapeRight:
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)\tlandscapeRight", level: .dbg)
            NSLayoutConstraint.activate([
                shootingButtonLandscapeRightOfCenterYGuide,
                shootingButtonLandscapeRightOfRightGuide,
            ])
            return
        default:
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)\tportrait", level: .dbg)
            NSLayoutConstraint.activate([
                shootingButtonPortraitOfCenterXGuide,
                shootingButtonPortraitOfBottomGuide,
            ])
            return
        }
    }

    @objc private func shooting(_ sender: UIButton) {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        shooting()
    }

    func shooting() {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        let settings = AVCapturePhotoSettings()
        // NOTE: オートフラッシュ
        settings.flashMode = .auto
        // NOTE: 手ブレ補正 ON
        settings.isAutoStillImageStabilizationEnabled = true
        guard let photoOut = photoOut else {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                + "\nphotoOut is nil"
                , level: .err)
            return
        }
        photoOut.capturePhoto(with: settings, delegate: self)
    }

    private func setupCloseButton() {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        closeButton.setImage(UIImage(systemName: "multiply")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeCamera), for: .touchUpInside)
        view.addSubview(closeButton)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        let topGuide = closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        let trailingGuide = closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -30)
        NSLayoutConstraint.activate([topGuide, trailingGuide])
    }

    @objc func closeCamera(_ sender: UIButton) {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        dismiss(animated: true)
    }
}

@available(iOS 13.0, *)
extension Camera4iOS13OrAboveViewController: AVCapturePhotoCaptureDelegate {
    /// 撮影直後のコールバック
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        if let error = error {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)\terror: \(error)", level: .err)
            return
        }
        if let imageData = photo.fileDataRepresentation() {
            guard let uiImage = UIImage(data: imageData) else {
                debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .err)
                return
            }

            // NOTE: フォトライブラリへ保存
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        }
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

extension UIImage {
    func rotatedBy(degree: CGFloat) -> UIImage {
        let radian = -degree * CGFloat.pi / 180
        UIGraphicsBeginImageContext(self.size)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: self.size.width / 2, y: self.size.height / 2)
        context.scaleBy(x: 1.0, y: -1.0)

        context.rotate(by: radian)
        context.draw(self.cgImage!, in: CGRect(x: -(self.size.width / 2), y: -(self.size.height / 2), width: self.size.width, height: self.size.height))

        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return rotatedImage
    }
}

extension UIDeviceOrientation: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portraitUpsideDown"
        case .landscapeLeft: return "landscapeLeft"
        case .landscapeRight: return "landscapeRight"
        case .faceUp: return "faceUp"
        case .faceDown: return "faceDown"
        @unknown default: return "default"
        }
    }
}

extension AVCaptureVideoOrientation: CustomStringConvertible {
    public var description: String {
        switch self {
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portraitUpsideDown"
        case .landscapeRight: return "landscapeRight"
        case .landscapeLeft: return "landscapeLeft"
        @unknown default: return "default"
        }
    }
}
