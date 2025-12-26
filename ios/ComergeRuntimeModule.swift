import ExpoModulesCore

public class ComergeRuntimeModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ComergeRuntime")

    View(ComergeRuntimeExpoView.self) {
      Prop("appKey") { (view: ComergeRuntimeExpoView, value: String?) in
        view.setAppKey(value)
      }

      Prop("bundlePath") { (view: ComergeRuntimeExpoView, value: String?) in
        view.setBundlePath(value)
      }

      Prop("initialProps") { (view: ComergeRuntimeExpoView, value: [String: Any]?) in
        view.setInitialProps(value)
      }
    }
  }
}
