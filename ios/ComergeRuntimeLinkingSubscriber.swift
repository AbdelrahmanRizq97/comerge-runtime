import ExpoModulesCore

public let comergeRuntimeOnURLReceivedNotification = Notification.Name("ComergeRuntimeOnURLReceived")

public class ComergeRuntimeLinkingSubscriber: ExpoAppDelegateSubscriber {
  #if os(iOS) || os(tvOS)
  public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    ComergeRuntimeLinkingState.setInitialURL(url)
    NotificationCenter.default.post(
      name: comergeRuntimeOnURLReceivedNotification,
      object: self,
      userInfo: ["url": url]
    )
    return false
  }
  #elseif os(macOS)
  public func application(_ application: NSApplication, open urls: [URL]) {
    guard let url = urls.first else {
      return
    }
    ComergeRuntimeLinkingState.setInitialURL(url)
    NotificationCenter.default.post(
      name: comergeRuntimeOnURLReceivedNotification,
      object: self,
      userInfo: ["url": url]
    )
  }
  #endif

  public func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([any UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
      if ComergeRuntimeLinkingState.initialURL() == nil {
        ComergeRuntimeLinkingState.setInitialURL(url)
      }
      NotificationCenter.default.post(
        name: comergeRuntimeOnURLReceivedNotification,
        object: self,
        userInfo: ["url": url]
      )
      return true
    }
    return false
  }
}
