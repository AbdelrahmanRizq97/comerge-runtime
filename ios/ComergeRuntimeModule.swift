import ExpoModulesCore

public class ComergeRuntimeModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ComergeRuntime")

    Events("onRuntimeMessage")

    OnStartObserving("onRuntimeMessage") {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleHostMessageNotification),
        name: comergeRuntimeOnHostMessageNotification,
        object: nil
      )
    }

    OnStopObserving("onRuntimeMessage") {
      // swiftlint:disable:next notification_center_detachment
      NotificationCenter.default.removeObserver(self, name: comergeRuntimeOnHostMessageNotification, object: nil)
    }

    Function("emitSystemEvent") { (envelope: [String: Any]) -> Bool in
      guard ComergeRuntimeBridgeValidation.isValidEnvelope(envelope, requireMicroSource: true) else {
        return false
      }
      return ComergeRuntimeBridge.shared.dispatchMicroToHost(envelope: envelope)
    }

    Function("postMessageToRuntime") { (envelope: [String: Any]) -> Bool in
      guard ComergeRuntimeBridgeValidation.isValidEnvelope(envelope, requireMicroSource: false) else {
        return false
      }
      return ComergeRuntimeBridge.shared.dispatchHostToMicro(envelope: envelope)
    }

    View(ComergeRuntimeExpoView.self) {
      Events("onMessage")

      Prop("appKey") { (view: ComergeRuntimeExpoView, value: String?) in
        view.setAppKey(value)
      }

      Prop("bundlePath") { (view: ComergeRuntimeExpoView, value: String?) in
        view.setBundlePath(value)
      }

      Prop("runtimeId") { (view: ComergeRuntimeExpoView, value: String?) in
        view.setRuntimeId(value)
      }

      Prop("initialProps") { (view: ComergeRuntimeExpoView, value: [String: Any]?) in
        view.setInitialProps(value)
      }
    }
  }

  @objc private func handleHostMessageNotification(_ notification: Notification) {
    guard let envelope = notification.userInfo?["envelope"] as? [String: Any] else {
      return
    }
    sendEvent("onRuntimeMessage", ["envelope": envelope])
  }
}
