package expo.modules.comergeruntime

import java.lang.ref.WeakReference
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicReference

internal object ComergeRuntimeBridge {
  private val viewsByRuntimeId = ConcurrentHashMap<String, WeakReference<ComergeRuntimeView>>()
  private val lastActiveRuntimeId = AtomicReference<String?>(null)

  fun register(runtimeId: String, view: ComergeRuntimeView) {
    if (runtimeId.isBlank()) return
    viewsByRuntimeId[runtimeId] = WeakReference(view)
    lastActiveRuntimeId.set(runtimeId)
  }

  fun unregister(runtimeId: String?, view: ComergeRuntimeView) {
    if (runtimeId.isNullOrBlank()) return
    val existing = viewsByRuntimeId[runtimeId]?.get()
    if (existing == null || existing === view) {
      viewsByRuntimeId.remove(runtimeId)
    }
  }

  private fun findTarget(runtimeId: String?): ComergeRuntimeView? {
    val explicit = runtimeId?.takeIf { it.isNotBlank() }?.let { id ->
      val view = viewsByRuntimeId[id]?.get()
      if (view == null) {
        viewsByRuntimeId.remove(id)
      }
      view
    }
    if (explicit != null) return explicit
    val fallbackId = lastActiveRuntimeId.get()
    if (fallbackId.isNullOrBlank()) return null
    val fallback = viewsByRuntimeId[fallbackId]?.get()
    if (fallback == null) {
      viewsByRuntimeId.remove(fallbackId)
    }
    return fallback
  }

  fun dispatchMicroToHost(envelope: Map<String, Any?>): Boolean {
    val runtimeId = envelope["runtimeId"] as? String
    val view = findTarget(runtimeId) ?: return false
    return view.dispatchMicroEnvelope(envelope)
  }

  fun dispatchHostToMicro(envelope: Map<String, Any?>): Boolean {
    val runtimeId = envelope["runtimeId"] as? String
    val view = findTarget(runtimeId) ?: return false
    return view.dispatchHostEnvelope(envelope)
  }
}
