import UIKit
import AVFoundation
import SwiftUI

protocol PhotoShootDelegate {
    func shooting() -> Void
}

@available(iOS 13.0, *)
final class Camera4iOS13OrAboveViewController: UIViewController {
    enum CameraSide {
        case front
            , back
    }
    enum FrontCameraMode {
        case normalWideAngle
            , trueDepth
            , none
    }
    enum BackCameraMode {
        case normalWideAngle
            , dual
            , dualWideAngle
            , triple
            , ultraWide
            , telescope
            , none
    }
    private var defaultCameraSide: CameraSide
    private var frontCameraMode: FrontCameraMode
    private var backCameraMode: BackCameraMode
    private var captureSession: AVCaptureSession = AVCaptureSession()

    private var backCamera: AVCaptureDevice?
    private var frontCamera: AVCaptureDevice?
    private var currentCamera: AVCaptureDevice?

    private var previewLayer: AVCaptureVideoPreviewLayer?

    private let shootingButton: UIButton = UIButton()
    private let closeButton: UIButton = UIButton()

    private var _photoOut: Any?
    private var photoOut: AVCapturePhotoOutput? {
        get {
            _photoOut as? AVCapturePhotoOutput
        }
        set {
            _photoOut = newValue
        }
    }


    private var shootingButtonPortraitGuides: [NSLayoutConstraint]!
    private var shootingButtonLandscapeLeftGuides: [NSLayoutConstraint]!
    private var shootingButtonLandscapeRightYGuides: [NSLayoutConstraint]!
    private var shootingButtonPortraitUpsideDownGuides: [NSLayoutConstraint]! // not work on device with notch

    private var autoFocusAdjustTimer: Timer?

    private let focusIndicator: UIView = UIView()

    private let sessionQueue: DispatchQueue = DispatchQueue(label: "session queue")
    private var exZoomFactor: CGFloat = 1.0
    private var cameraObservation: NSKeyValueObservation?

    init(defaultCameraSide: CameraSide, frontCameraMode: FrontCameraMode, backCameraMode: BackCameraMode) {
        self.defaultCameraSide = defaultCameraSide
        self.frontCameraMode = frontCameraMode
        self.backCameraMode = backCameraMode
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        super.viewDidLoad()

        setupAVCaptureSession()
        setupAVCaptureDevice()
        setupCameraIO()
        captureSession.startRunning()

        setupPreviewLayer()

        setupCameraControlButton()

        setupFocusIndicator()

        setupAutofocusTimer()

        // NOTE: 回転時の通知を設定して videoOrientation を変更
        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        if let autoFocusAdjustTimer = autoFocusAdjustTimer {
            autoFocusAdjustTimer.invalidate()
        }
        super.viewDidDisappear(animated)
    }

    @objc private func onOrientationChanged() {
        let orientation = UIDevice.current.orientation
        guard orientation == .portrait || orientation == .landscapeLeft || orientation == .landscapeRight else {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                + "\nupside down is not supported."
                , level: .err)
            return
        }
        guard let previewLayer = previewLayer, let connection = previewLayer.connection else {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                + "\npreviewLayer or previewLayer?.connection is nil"
                , level: .err)
            return
        }
        connection.videoOrientation = Self.getOrientationAsAVCaptureVideoOrientation()

        previewLayer.frame = view.frame
        setupButtonLocation()
    }

    private func setupAVCaptureSession() {
        captureSession.sessionPreset = .photo
    }

    private func setupAVCaptureDevice() {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
            + "\nAVCaptureDevice.DeviceType"
            + "\n.builtInTripleCamera   : \(AVCaptureDevice.DeviceType.builtInTripleCamera   .rawValue)"
            + "\n.builtInDualCamera     : \(AVCaptureDevice.DeviceType.builtInDualCamera     .rawValue)"
            + "\n.builtInDualWideCamera : \(AVCaptureDevice.DeviceType.builtInDualWideCamera .rawValue)"
            + "\n.builtInWideAngleCamera: \(AVCaptureDevice.DeviceType.builtInWideAngleCamera.rawValue)"
            + "\n.builtInUltraWideCamera: \(AVCaptureDevice.DeviceType.builtInUltraWideCamera.rawValue)"
            + "\n.builtInTrueDepthCamera: \(AVCaptureDevice.DeviceType.builtInTrueDepthCamera.rawValue)"
            + "\n.builtInTelephotoCamera: \(AVCaptureDevice.DeviceType.builtInTelephotoCamera.rawValue)"
            , level: .dbg)
        let backVideoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
//                .builtInTripleCamera,    // 三眼
//                .builtInDualCamera,      // 二眼
//                .builtInDualWideCamera,  // 二眼広角
                .builtInWideAngleCamera, // 広角(ノーマルカメラ)
                .builtInUltraWideCamera, // 超広角
                .builtInTelephotoCamera, // 望遠
            ],
            mediaType: .video,
            position: .back
        )
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
            + "\nbackVideoDeviceDiscoverySession.devices.count: \(backVideoDeviceDiscoverySession.devices.count)"
            + "\n\tbackVideoDeviceDiscoverySession.devices: \(backVideoDeviceDiscoverySession.devices)"
            , level: .dbg)
        if let detectedBackCamera = backVideoDeviceDiscoverySession.devices.first {
            backCamera = detectedBackCamera
            currentCamera = backCamera
        }

        let frontVideoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera, // 広角(ノーマルカメラ)
                .builtInTrueDepthCamera, // トゥルーデプス
            ],
            mediaType: .video,
            position: .front
        )
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
            + "\nfrontVideoDeviceDiscoverySession.devices.count: \(frontVideoDeviceDiscoverySession.devices.count)"
            + "\n\tfrontVideoDeviceDiscoverySession.devices: \(frontVideoDeviceDiscoverySession.devices)"
            , level: .dbg)
        if let detectedFrontCamera = frontVideoDeviceDiscoverySession.devices.first {
            frontCamera = detectedFrontCamera
        }

        if let currentCamera = currentCamera {
            exZoomFactor = currentCamera.videoZoomFactor
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                + "\n\tfrontCamera: \(frontCamera)"
                + "\n\tbackCamera: \(backCamera)"
                + "\n\tcurrentCamera: \(currentCamera)"
                + "\n\t\t.videoZoomFactor: \(currentCamera.videoZoomFactor)"
                + "\n\t\t.minAvailableVideoZoomFactor: \(currentCamera.minAvailableVideoZoomFactor)"
                + "\n\t\t.maxAvailableVideoZoomFactor: \(currentCamera.maxAvailableVideoZoomFactor)"
                + "\n\t\t.activeFormat.videoMaxZoomFactor: \(currentCamera.activeFormat.videoMaxZoomFactor)"
                , level: .dbg)
            cameraObservation = currentCamera.observe(\.isConnected) { [weak self] camera, changeValue in
                guard let self = self, let isConnected = changeValue.newValue, isConnected else {
                    debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .err)
                    return
                }
                debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
                self.modifyZoomFactor(byScale: 2, isFix: true)
                if let cameraObservation = self.cameraObservation {
                    cameraObservation.invalidate()
                }
            }
//            currentCamera.isConnected
        }
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
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGesture(_:))))
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinchGesture(_:))))
    }

    @objc func tapGesture(_ gesture: UITapGestureRecognizer) {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        let tappedPoint = gesture.location(in: gesture.view)
        adjustAutoFocus(focusPoint: tappedPoint, focusMode: .autoFocus, exposeMode: .autoExpose)
    }

    @objc func pinchGesture(_ gesture: UIPinchGestureRecognizer) {
//        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
//            + "\ngesture.scale: \(gesture.scale)"
//            + "\ngesture.velocity: \(gesture.velocity)"
//            , level: .dbg)
//        guard gesture.state == UIPinchGestureRecognizer.State.ended else {
//            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .err)
//            return
//        }
//        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        modifyZoomFactor(byScale: gesture.scale, isFix: gesture.state == UIPinchGestureRecognizer.State.ended)
    }

    // ref: https://qiita.com/touyu/items/6fd26a35212e75f98c6b
    private func modifyZoomFactor(byScale pinchScale: CGFloat, isFix: Bool) {
        guard let currentCamera = currentCamera else {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                + "\nNo active camera found."
                , level: .err)
            return
        }
        do {
            try currentCamera.lockForConfiguration()
        } catch {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                + "\nfailed to lock for configuration for current camera."
                , level: .err)
            return
        }

        var newZoomFactor: CGFloat = currentCamera.videoZoomFactor
        defer {
            currentCamera.videoZoomFactor = newZoomFactor
            currentCamera.unlockForConfiguration()
        }

        if pinchScale > 1.0 {
            newZoomFactor = exZoomFactor + pinchScale - 1
        } else {
            newZoomFactor = exZoomFactor - (1 - pinchScale) * exZoomFactor
        }

        if newZoomFactor < currentCamera.minAvailableVideoZoomFactor {
            newZoomFactor = currentCamera.minAvailableVideoZoomFactor
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                + "\nVideo scale factor capped to \(newZoomFactor)."
                , level: .dbg)
        } else if newZoomFactor > currentCamera.maxAvailableVideoZoomFactor {
            newZoomFactor = currentCamera.maxAvailableVideoZoomFactor
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                + "\nVideo scale factor capped to \(newZoomFactor)."
                , level: .dbg)
        }

        if isFix {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                + "\nFix video scale factor from \(exZoomFactor) to \(newZoomFactor)"
                + "\n\t\t.videoZoomFactor: \(currentCamera.videoZoomFactor)"
                + "\n\t\t.minAvailableVideoZoomFactor: \(currentCamera.minAvailableVideoZoomFactor)"
                + "\n\t\t.maxAvailableVideoZoomFactor: \(currentCamera.maxAvailableVideoZoomFactor)"
                + "\n\t\t.activeFormat.videoMaxZoomFactor: \(currentCamera.activeFormat.videoMaxZoomFactor)"
                , level: .dbg)
            exZoomFactor = newZoomFactor
        }
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

    private func setupCameraControlButton() {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        setupShootingButton()
        setupCloseButton()
        // todo: その他ボタンや表示
        setupButtonLocation()
    }

    private func setupFocusIndicator() {
        focusIndicator.frame = CGRect(x: 0, y: 0, width: view.bounds.width * 0.3, height: view.bounds.width * 0.3)
        focusIndicator.layer.borderWidth = 1
        focusIndicator.layer.borderColor = UIColor.systemYellow.cgColor
        focusIndicator.isHidden = true
        view.addSubview(focusIndicator)
    }

    private func setupShootingButton() {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        shootingButton.backgroundColor = .white
        shootingButton.addTarget(self, action: #selector(shooting(_:)), for: .touchDown)
        view.addSubview(shootingButton)

        shootingButton.translatesAutoresizingMaskIntoConstraints = false

        shootingButtonPortraitGuides = [
            shootingButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shootingButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
        ]

        shootingButtonLandscapeLeftGuides = [
            shootingButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            shootingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
        ]

        shootingButtonLandscapeRightYGuides = [
            shootingButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            shootingButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
        ]

        shootingButtonPortraitUpsideDownGuides = [
            shootingButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shootingButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ]

        NSLayoutConstraint.activate([
            shootingButton.widthAnchor.constraint(equalToConstant: 60),
            shootingButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }

    @objc private func shooting(_ sender: UIButton) {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        shooting()
    }

    private func setupButtonLocation() {
        NSLayoutConstraint.deactivate(
            shootingButtonPortraitGuides
                + shootingButtonLandscapeLeftGuides
                + shootingButtonLandscapeRightYGuides
                + shootingButtonPortraitUpsideDownGuides
        )
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)\tportraitUpsideDown", level: .dbg)
            NSLayoutConstraint.activate(shootingButtonPortraitUpsideDownGuides)
        case .landscapeLeft:
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)\tlandscapeLeft", level: .dbg)
            NSLayoutConstraint.activate(shootingButtonLandscapeLeftGuides)
            return
        case .landscapeRight:
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)\tlandscapeRight", level: .dbg)
            NSLayoutConstraint.activate(shootingButtonLandscapeRightYGuides)
            return
        default:
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)\tportrait", level: .dbg)
            NSLayoutConstraint.activate(shootingButtonPortraitGuides)
            return
        }
    }

    private func setupCloseButton() {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        closeButton.setImage(UIImage(systemName: "multiply")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = .white
        closeButton.sizeToFit()
        closeButton.imageView?.contentMode = .scaleAspectFit
        closeButton.contentHorizontalAlignment = .fill
        closeButton.contentVerticalAlignment = .fill
        closeButton.addTarget(self, action: #selector(closeCamera), for: .touchUpInside)
        view.addSubview(closeButton)

        closeButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -30),
        ])
    }

    @objc func closeCamera(_ sender: UIButton) {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        dismiss(animated: true)
    }

    private func setupAutofocusTimer() {
        guard autoFocusAdjustTimer == nil else {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                + "\nAlready set observed timer."
                , level: .err)
            return
        }
        autoFocusAdjustTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(adjustAutoFocus(_:)), userInfo: nil, repeats: true)
    }

    @objc func adjustAutoFocus(_ timer: Timer) {
        adjustAutoFocus(focusPoint: view.center, focusMode: .continuousAutoFocus, exposeMode: .continuousAutoExposure)
    }

    // ref: https://qiita.com/jumperson/items/723737ed497fe2c6f2aa
    private func adjustAutoFocus(focusPoint: CGPoint, focusMode: AVCaptureDevice.FocusMode, exposeMode: AVCaptureDevice.ExposureMode) {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        focusIndicator.center = focusPoint // タップしたポイントへ移動する
        focusIndicator.isHidden = false // 現れる
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.5, delay: 0, options: []) {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
            self.focusIndicator.frame = CGRect(
                x: focusPoint.x - (self.view.bounds.width * 0.075),
                y: focusPoint.y - (self.view.bounds.width * 0.075),
                width: (self.view.bounds.width * 0.15),
                height: (self.view.bounds.width * 0.15)
            ) // タップしたポイントに向けて縮む
        } completion: { (UIViewAnimatingPosition) in
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (Timer) in
                debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
                self.focusIndicator.isHidden = true // 少し待ってから消える
                self.focusIndicator.frame.size = CGSize(
                    width: self.view.bounds.width * 0.3,
                    height: self.view.bounds.width * 0.3
                ) // 少し大きめのサイズに戻しておく
            }
        }

        guard let currentCamera = currentCamera else {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                + "\nNo active camera found."
                , level: .err)
            return
        }
        do {
            try currentCamera.lockForConfiguration()
        } catch {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                + "\nfailed to lock for configuration for current camera."
                , level: .err)
            return
        }
        defer {
            currentCamera.unlockForConfiguration()
        }

        guard let previewLayer = previewLayer else {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)"
                + "\npreview layer is nil."
                , level: .err)
            return
        }
        let focusPoint4CaptureDevice = previewLayer.captureDevicePointConverted(fromLayerPoint: focusPoint)

        // NOTE: フォーカス調整
        if currentCamera.isFocusPointOfInterestSupported && currentCamera.isFocusModeSupported(focusMode) {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
            currentCamera.focusMode = focusMode
            currentCamera.focusPointOfInterest = focusPoint4CaptureDevice
        }

        // NOTE: 露光調整
        if currentCamera.isExposurePointOfInterestSupported && currentCamera.isExposureModeSupported(exposeMode) {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
            currentCamera.exposureMode = exposeMode
            currentCamera.exposurePointOfInterest = focusPoint4CaptureDevice
        }
    }
}

@available(iOS 13.0, *)
extension Camera4iOS13OrAboveViewController: PhotoShootDelegate {
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
        Camera4iOS13OrAboveViewController(defaultCameraSide: .front, frontCameraMode: .normalWideAngle, backCameraMode: .normalWideAngle)
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
