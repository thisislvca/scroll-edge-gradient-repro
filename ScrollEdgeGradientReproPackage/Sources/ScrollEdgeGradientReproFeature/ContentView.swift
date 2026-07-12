import SwiftUI
import UIKit

public struct ContentView: View {
    public init() {}

    public var body: some View {
        ResearchTabController()
            .ignoresSafeArea()
    }
}

private struct ResearchTabController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UITabBarController {
        let tabController = UITabBarController()
        tabController.viewControllers = GradientExperiment.allCases.map { experiment in
            let screen = HealthGradientViewController(experiment: experiment)
            screen.tabBarItem = UITabBarItem(
                title: experiment.tabTitle,
                image: UIImage(systemName: experiment.tabImage),
                selectedImage: UIImage(systemName: experiment.tabImage + ".fill")
            )
            let navigationController = UINavigationController(rootViewController: screen)
            navigationController.navigationBar.prefersLargeTitles = true
            return navigationController
        }
        tabController.selectedIndex = ProcessInfo.processInfo.arguments.contains("--one-pass") ? 1 : 0
        return tabController
    }

    func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {}
}

private extension GradientExperiment {
    static let allCases: [GradientExperiment] = [.separated, .onePass]
}
