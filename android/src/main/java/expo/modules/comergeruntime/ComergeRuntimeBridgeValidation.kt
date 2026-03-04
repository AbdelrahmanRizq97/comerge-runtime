package expo.modules.comergeruntime

internal object ComergeRuntimeBridgeValidation {
  fun isValidEnvelope(envelope: Map<String, Any?>, requireMicroSource: Boolean): Boolean {
    val v = envelope["v"]
    val version = (v as? Number)?.toInt()
    val type = envelope["type"] as? String
    val requestId = envelope["requestId"] as? String
    val ts = envelope["ts"]
    val source = envelope["source"] as? String
    if (version != 1) return false
    if (type.isNullOrBlank()) return false
    if (requestId.isNullOrBlank()) return false
    if (ts !is Number) return false
    if (source != "host" && source != "micro") return false
    if (requireMicroSource && source != "micro") return false
    if (requireMicroSource && type !in ComergeRuntimeContracts.ALLOWED_SYSTEM_EVENT_TYPES) return false
    val approxSize = envelope.toString().length
    if (approxSize > ComergeRuntimeContracts.MAX_BRIDGE_PAYLOAD_CHARS) return false
    return true
  }
}
