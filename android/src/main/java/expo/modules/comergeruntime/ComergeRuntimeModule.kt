package expo.modules.comergeruntime

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class ComergeRuntimeModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("ComergeRuntime")

    View(ComergeRuntimeView::class) {
      Prop("appKey") { view: ComergeRuntimeView, value: String? ->
        view.setAppKey(value)
      }

      Prop("bundlePath") { view: ComergeRuntimeView, value: String? ->
        view.setBundlePath(value)
      }

      Prop("initialProps") { view: ComergeRuntimeView, value: Map<String, Any?>? ->
        view.setInitialProps(value)
      }
    }
  }
}
