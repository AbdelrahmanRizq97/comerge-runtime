package expo.modules.comergeruntime

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class ComergeRuntimeModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("ComergeRuntime")

    Events("onRuntimeMessage")

    Function("emitSystemEvent") { envelope: Map<String, Any?> ->
      if (!ComergeRuntimeBridgeValidation.isValidEnvelope(envelope, requireMicroSource = true)) {
        return@Function false
      }
      ComergeRuntimeBridge.dispatchMicroToHost(envelope)
    }

    Function("postMessageToRuntime") { envelope: Map<String, Any?> ->
      if (!ComergeRuntimeBridgeValidation.isValidEnvelope(envelope, requireMicroSource = false)) {
        return@Function false
      }
      ComergeRuntimeBridge.dispatchHostToMicro(envelope)
    }

    View(ComergeRuntimeView::class) {
      Events("onMessage")

      Prop("appKey") { view: ComergeRuntimeView, value: String? ->
        view.setAppKey(value)
      }

      Prop("bundlePath") { view: ComergeRuntimeView, value: String? ->
        view.setBundlePath(value)
      }

      Prop("runtimeId") { view: ComergeRuntimeView, value: String? ->
        view.setRuntimeId(value)
      }

      Prop("initialProps") { view: ComergeRuntimeView, value: Map<String, Any?>? ->
        view.setInitialProps(value)
      }
    }
  }
}
