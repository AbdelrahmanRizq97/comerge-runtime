import ExpoModulesCore

private let onURLReceivedEvent = "onURLReceived"

public class ComergeRuntimeExpoLinkingModule: Module {
  public func definition() -> ModuleDefinition {
    // Override ExpoLinking for micro-app runtime isolation.
    Name("ExpoLinking")

    Events(onURLReceivedEvent)

    OnStartObserving(onURLReceivedEvent) {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleURLReceivedNotification),
        name: comergeRuntimeOnURLReceivedNotification,
        object: nil
      )
    }

    OnStopObserving(onURLReceivedEvent) {
      // swiftlint:disable:next notification_center_detachment
      NotificationCenter.default.removeObserver(self, name: comergeRuntimeOnURLReceivedNotification, object: nil)
    }

    Function("getLinkingURL") {
      if ComergeRuntimeLinkingState.isMicroRuntimeActive() {
        return nil as String?
      }
      return ComergeRuntimeLinkingState.initialURL()?.absoluteString
    }
  }

  @objc private func handleURLReceivedNotification(_ notification: Notification) {
    if ComergeRuntimeLinkingState.isMicroRuntimeActive() {
      return
    }
    guard let url = notification.userInfo?["url"] as? URL else {
      return
    }
    sendEvent(onURLReceivedEvent, ["url": url.absoluteString])
  }
}
