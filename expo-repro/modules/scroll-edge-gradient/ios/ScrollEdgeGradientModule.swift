import ExpoModulesCore

public class ScrollEdgeGradientModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ScrollEdgeGradient")

    View(ScrollEdgeGradientView.self) {
      Prop("colors") { (view: ScrollEdgeGradientView, colors: [String]) in
        view.colors = colors
      }

      Prop("heightFraction") { (view: ScrollEdgeGradientView, heightFraction: Double) in
        view.heightFraction = heightFraction
      }

      Prop("mode") { (view: ScrollEdgeGradientView, mode: String) in
        view.mode = mode
      }
    }
  }
}
