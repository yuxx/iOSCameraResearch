import UIKit
import AVFoundation
import SwiftUI

// ref: https://qiita.com/t_okkan/items/f2ba9b7009b49fc2e30a
final class ViewController: UIViewController {
    let proceed2normalCameraButton: UIButton = UIButton()
    let proceed2dualCameraButton: UIButton = UIButton()
    let proceed2dualWideCameraButton: UIButton = UIButton()
    let proceed2tripleCameraButton: UIButton = UIButton()
    let proceed2ultraWideCameraButton: UIButton = UIButton()
    let proceed2telescopeCameraButton: UIButton = UIButton()
    let proceed2frontCameraButton: UIButton = UIButton()
    let proceed2trueDepthCameraButton: UIButton = UIButton()
    let proceed2backAndFrontCameraButton: UIButton = UIButton()

    enum Mode: Int {
        case backOnly = 0
            , dualOnly
            , dualWideOnly
            , tripleOnly
            , ultraWideOnly
            , telescopeOnly
            , frontOnly
            , trueDepthOnly
            , backAndFront
    }

    let scrollView: UIScrollView = UIScrollView()
    let contentView: UIView = UIView()

    override func viewDidLoad() {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        super.viewDidLoad()

        view.frame = CGRect(origin: .zero, size: UIScreen.main.bounds.size)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: -safeAreaTop).isActive = true
        contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: safeAreaBottom).isActive = true

        view.backgroundColor = .white
        scrollView.backgroundColor = .lightGray
        contentView.backgroundColor = .gray

        setupButton()
    }

    private func setupButton() {
        proceed2normalCameraButton.setTitle("ノーマルカメラ", for: .normal)
        proceed2normalCameraButton.setTitleColor(.white, for: .normal)
        proceed2normalCameraButton.backgroundColor = .green
        proceed2normalCameraButton.addTarget(self, action: #selector(proceed2cameraAction), for: .touchUpInside)
        proceed2normalCameraButton.tag = Mode.backOnly.rawValue
        contentView.addSubview(proceed2normalCameraButton)

        // ref: https://qiita.com/yucovin/items/4bebcc7a8b1088b374c9
        proceed2normalCameraButton.translatesAutoresizingMaskIntoConstraints = false
        let centeringGuide = proceed2normalCameraButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        let topGuide: NSLayoutConstraint
        if #available(iOS 11.0, *) {
            topGuide = proceed2normalCameraButton.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 60)
        } else {
            topGuide = proceed2normalCameraButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 60)
        }
        let widthGuide = proceed2normalCameraButton.widthAnchor.constraint(equalToConstant: 300)
        let heightGuide = proceed2normalCameraButton.heightAnchor.constraint(equalToConstant: 40)
        NSLayoutConstraint.activate([centeringGuide, topGuide, widthGuide, heightGuide])

        addButton(button: proceed2dualCameraButton, title: "二眼カメラ", topAnchorTarget: proceed2normalCameraButton, mode: .dualOnly)
        addButton(button: proceed2dualWideCameraButton, title: "二眼広角カメラ", topAnchorTarget: proceed2dualCameraButton, mode: .dualWideOnly)
        addButton(button: proceed2tripleCameraButton, title: "三眼カメラ", topAnchorTarget: proceed2dualWideCameraButton, mode: .tripleOnly)
        addButton(button: proceed2ultraWideCameraButton, title: "超広角カメラ", topAnchorTarget: proceed2tripleCameraButton, mode: .ultraWideOnly)
        addButton(button: proceed2telescopeCameraButton, title: "望遠カメラ", topAnchorTarget: proceed2ultraWideCameraButton, mode: .telescopeOnly)
        addButton(button: proceed2frontCameraButton, title: "フロントカメラ", topAnchorTarget: proceed2telescopeCameraButton, mode: .frontOnly)
        addButton(button: proceed2trueDepthCameraButton, title: "トゥルーデプスカメラ", topAnchorTarget: proceed2frontCameraButton, mode: .trueDepthOnly)
        addButton(button: proceed2backAndFrontCameraButton, title: "ノーマルバック&フロントカメラ", topAnchorTarget: proceed2trueDepthCameraButton, mode: .backAndFront)

        contentView.bottomAnchor.constraint(equalTo: proceed2backAndFrontCameraButton.bottomAnchor, constant: safeAreaBottom).isActive = true
    }

    private func addButton(button: UIButton, title: String, topAnchorTarget prevButton: UIButton, mode: Mode) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .green
        button.addTarget(self, action: #selector(proceed2cameraAction), for: .touchUpInside)
        button.tag = mode.rawValue
        contentView.addSubview(button)

        button.translatesAutoresizingMaskIntoConstraints = false
        let centeringGuide = button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        let topGuide = button.topAnchor.constraint(equalTo: prevButton.bottomAnchor, constant: 60)
        let widthGuide = button.widthAnchor.constraint(equalToConstant: 300)
        let heightGuide = button.heightAnchor.constraint(equalToConstant: 40)
        NSLayoutConstraint.activate([centeringGuide, topGuide, widthGuide, heightGuide])
    }

    @objc private func proceed2cameraAction(_ sender: UIButton) {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        guard let mode = Mode(rawValue: sender.tag) else {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line) unknown mode id: \(sender.tag)", level: .err)
            return
        }
        if #available(iOS 13.0, *) {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
            let vc: UIViewController
            switch mode {
            case .backOnly:
                vc = Camera4iOS13OrAboveViewController(defaultCameraSide: .back, frontCameraMode: .none, backCameraMode: .normalWideAngle)
            case .dualOnly:
                vc = Camera4iOS13OrAboveViewController(defaultCameraSide: .back, frontCameraMode: .none, backCameraMode: .dual)
            case .dualWideOnly:
                vc = Camera4iOS13OrAboveViewController(defaultCameraSide: .back, frontCameraMode: .none, backCameraMode: .dualWideAngle)
            case .tripleOnly:
                vc = Camera4iOS13OrAboveViewController(defaultCameraSide: .back, frontCameraMode: .none, backCameraMode: .triple)
            case .ultraWideOnly:
                vc = Camera4iOS13OrAboveViewController(defaultCameraSide: .back, frontCameraMode: .none, backCameraMode: .ultraWide)
            case .telescopeOnly:
                vc = Camera4iOS13OrAboveViewController(defaultCameraSide: .back, frontCameraMode: .none, backCameraMode: .telescope)
            case .frontOnly:
                vc = Camera4iOS13OrAboveViewController(defaultCameraSide: .front, frontCameraMode: .normalWideAngle, backCameraMode: .none)
            case .trueDepthOnly:
                vc = Camera4iOS13OrAboveViewController(defaultCameraSide: .front, frontCameraMode: .trueDepth, backCameraMode: .none)
            case .backAndFront:
                vc = Camera4iOS13OrAboveViewController(defaultCameraSide: .back, frontCameraMode: .normalWideAngle, backCameraMode: .normalWideAngle)
            }
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true) {
                debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
            }
        } else {
            // todo:
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)\tTODO: implement", level: .dbg)
        }
    }
}

@available(iOS 13.0, *)
final class ViewControllerRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = ViewController

    func makeUIViewController(context: Context) -> UIViewControllerType {
        ViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }
}

@available(iOS 13.0, *)
struct ViewController_Previews: PreviewProvider {
    static var previews: some View {
        ViewControllerRepresentable()
    }
}

extension UIViewController {
    // ref: https://stackoverflow.com/a/46831519/15474670
    var safeAreaTop: CGFloat {
        guard #available(iOS 11.0, *) else {
            return 0
        }
        guard #available(iOS 13.0, *) else {
            guard let window = UIApplication.shared.keyWindow else {
                return 0
            }
            return window.safeAreaInsets.top
        }
        guard let window = UIApplication.shared.windows.first else {
            return 0
        }
        return window.safeAreaInsets.top
    }
    var safeAreaBottom: CGFloat {
        guard #available(iOS 11.0, *) else {
            return 0
        }
        guard #available(iOS 13.0, *) else {
            guard let window = UIApplication.shared.keyWindow else {
                return 0
            }
            return window.safeAreaInsets.bottom
        }
        guard let window = UIApplication.shared.windows.first else {
            return 0
        }
        return window.safeAreaInsets.bottom
    }
}
