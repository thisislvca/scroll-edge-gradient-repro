import SwiftUI
import UIKit

public struct ContentView: View {
    public init() {}

    public var body: some View {
        ResearchNavigationController()
            .ignoresSafeArea()
    }
}

private struct ResearchNavigationController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let rootViewController = HealthGradientViewController()
        let navigationController = UINavigationController(rootViewController: rootViewController)
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
