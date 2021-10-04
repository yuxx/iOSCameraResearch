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
        super.viewDidLoad()

        view.frame = CGRect(origin: .zero, size: UIScreen.main.bounds.size)

//        view.translatesAutoresizingMaskIntoConstraints = false
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
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true

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
        addButton(button: proceed2dualCameraButton, title: "二眼広角カメラ", topAnchorTarget: proceed2normalCameraButton, mode: .dualWideOnly)
        addButton(button: proceed2dualCameraButton, title: "三眼カメラ", topAnchorTarget: proceed2normalCameraButton, mode: .tripleOnly)
        addButton(button: proceed2dualCameraButton, title: "超広角カメラ", topAnchorTarget: proceed2normalCameraButton, mode: .ultraWideOnly)
        addButton(button: proceed2dualCameraButton, title: "望遠カメラ", topAnchorTarget: proceed2normalCameraButton, mode: .telescopeOnly)
        addButton(button: proceed2dualCameraButton, title: "フロントカメラ", topAnchorTarget: proceed2normalCameraButton, mode: .frontOnly)
        addButton(button: proceed2dualCameraButton, title: "トゥルーデプスカメラ", topAnchorTarget: proceed2normalCameraButton, mode: .trueDepthOnly)
        addButton(button: proceed2dualCameraButton, title: "ノーマルバック&フロントカメラ", topAnchorTarget: proceed2normalCameraButton, mode: .backAndFront)
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
