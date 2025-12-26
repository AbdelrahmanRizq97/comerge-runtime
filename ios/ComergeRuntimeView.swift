import ExpoModulesCore

public final class ComergeRuntimeExpoView: ExpoView {
  private let microAppView: UIView = {
    let viewClass = (NSClassFromString("ComergeRuntimeView") as? UIView.Type) ?? UIView.self
    return viewClass.init(frame: .zero)
  }()

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    clipsToBounds = true
    addSubview(microAppView)
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    microAppView.frame = bounds
  }

  func setAppKey(_ value: String?) {
    microAppView.setValue(value ?? "", forKey: "appKey")
  }

  func setBundlePath(_ value: String?) {
    microAppView.setValue(value ?? "", forKey: "bundlePath")
  }

  func setInitialProps(_ value: [String: Any]?) {
    microAppView.setValue((value ?? [:]) as NSDictionary, forKey: "initialProps")
  }
}
