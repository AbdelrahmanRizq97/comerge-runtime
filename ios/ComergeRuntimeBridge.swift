import Foundation

let comergeRuntimeOnHostMessageNotification = Notification.Name("ComergeRuntimeOnHostMessage")

final class ComergeRuntimeBridge {
  static let shared = ComergeRuntimeBridge()

  private let lock = NSLock()
  private let map = NSMapTable<NSString, ComergeRuntimeExpoView>(keyOptions: .copyIn, valueOptions: .weakMemory)
  private var lastActiveRuntimeId: String?

  private init() {}

  func register(runtimeId: String, view: ComergeRuntimeExpoView) {
    guard !runtimeId.isEmpty else { return }
    lock.lock()
    defer { lock.unlock() }
    map.setObject(view, forKey: runtimeId as NSString)
    lastActiveRuntimeId = runtimeId
  }

  func unregister(runtimeId: String, view: ComergeRuntimeExpoView) {
    guard !runtimeId.isEmpty else { return }
    lock.lock()
    defer { lock.unlock() }
    if let existing = map.object(forKey: runtimeId as NSString), existing === view {
      map.removeObject(forKey: runtimeId as NSString)
    }
  }

  private func resolveTarget(runtimeId: String?) -> ComergeRuntimeExpoView? {
    lock.lock()
    defer { lock.unlock() }
    if let runtimeId, !runtimeId.isEmpty, let explicit = map.object(forKey: runtimeId as NSString) {
      return explicit
    }
    if let last = lastActiveRuntimeId, !last.isEmpty {
      return map.object(forKey: last as NSString)
    }
    return nil
  }

  func dispatchMicroToHost(envelope: [String: Any]) -> Bool {
    let runtimeId = envelope["runtimeId"] as? String
    guard let view = resolveTarget(runtimeId: runtimeId) else {
      return false
    }
    return view.dispatchMicroEnvelope(envelope)
  }

  func dispatchHostToMicro(envelope: [String: Any]) -> Bool {
    let runtimeId = envelope["runtimeId"] as? String
    guard let view = resolveTarget(runtimeId: runtimeId) else { return false }
    return view.dispatchHostEnvelope(envelope)
  }
}
