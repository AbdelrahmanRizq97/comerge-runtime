import Foundation

internal enum ComergeRuntimeBridgeValidation {
  static let allowedSystemTypes: Set<String> = [
    "system.auth_get_token",
    "system.auth_step_up_google",
    "system.open_app_requested",
    "system.open_shell_settings_requested",
    "system.sign_out_requested",
    "system.account_deleted",
    "system.session_invalid",
  ]

  static func isValidEnvelope(_ envelope: [String: Any], requireMicroSource: Bool) -> Bool {
    guard let v = envelope["v"] as? NSNumber, v.intValue == 1 else { return false }
    guard let type = envelope["type"] as? String, !type.isEmpty else { return false }
    guard let requestId = envelope["requestId"] as? String, !requestId.isEmpty else { return false }
    guard envelope["ts"] is NSNumber else { return false }
    guard let source = envelope["source"] as? String, (source == "host" || source == "micro") else { return false }
    if requireMicroSource && source != "micro" { return false }
    if requireMicroSource && !allowedSystemTypes.contains(type) { return false }

    let approxSize = String(describing: envelope).count
    if approxSize > 64 * 1024 { return false }
    return true
  }
}
