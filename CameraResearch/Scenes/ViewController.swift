import UIKit
import AVFoundation
import SwiftUI

// ref: https://qiita.com/t_okkan/items/f2ba9b7009b49fc2e30a
final class ViewController: UIViewController {
    let proceed2cameraButton: UIButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.frame = CGRect(origin: .zero, size: UIScreen.main.bounds.size)

        view.backgroundColor = .gray

        setupButton()
    }

    private func setupButton() {
        proceed2cameraButton.setTitle("To camera", for: .normal)
        proceed2cameraButton.setTitleColor(.white, for: .normal)
        proceed2cameraButton.backgroundColor = .green
        proceed2cameraButton.addTarget(self, action: #selector(proceed2camera), for: .touchUpInside)
        view.addSubview(proceed2cameraButton)

        // ref: https://qiita.com/yucovin/items/4bebcc7a8b1088b374c9
        proceed2cameraButton.translatesAutoresizingMaskIntoConstraints = false
        let centeringGuide = proceed2cameraButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let topGuide: NSLayoutConstraint
        if #available(iOS 11.0, *) {
            topGuide = proceed2cameraButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60)
        } else {
            topGuide = proceed2cameraButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 60)
        }
        let widthGuide = proceed2cameraButton.widthAnchor.constraint(equalToConstant: 300)
        let heightGuide = proceed2cameraButton.heightAnchor.constraint(equalToConstant: 40)
        NSLayoutConstraint.activate([centeringGuide, topGuide, widthGuide, heightGuide])
    }

    @objc private func proceed2camera(_ sender: UIButton) {
        debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
        if #available(iOS 13.0, *) {
            debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
            let vc = Camera4iOS13OrAboveViewController()
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true) {
                debuglog("\(String(describing: Self.self))::\(#function)@\(#line)", level: .dbg)
            }
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
