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
            let navigationController = UINavigationController(rootViewController: screen)
            navigationController.navigationBar.prefersLargeTitles = true
            navigationController.tabBarItem = UITabBarItem(
                title: experiment.tabTitle,
                image: UIImage(systemName: experiment.tabImage),
                selectedImage: UIImage(systemName: experiment.tabImage)
            )
            return navigationController
        }
        let arguments = ProcessInfo.processInfo.arguments
        tabController.selectedIndex = arguments.contains("--in-scroll") || arguments.contains("--manna-bug") || arguments.contains("--dark-overlay") || arguments.contains("--flattened") || arguments.contains("--one-pass") ? 1 : 0
        return tabController
    }

    func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {}
}
