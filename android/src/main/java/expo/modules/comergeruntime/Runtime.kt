package expo.modules.comergeruntime

import android.app.Activity
import android.app.Application
import android.os.Bundle
import com.facebook.react.ReactApplication
import com.facebook.react.ReactHost
import com.facebook.react.ReactInstanceEventListener
import com.facebook.react.ReactPackage
import com.facebook.react.ReactNativeHost
import com.facebook.react.ReactPackageTurboModuleManagerDelegate
import com.facebook.react.bridge.JSBundleLoader
import com.facebook.react.bridge.ReactContext
import com.facebook.react.common.annotations.FrameworkAPI
import com.facebook.react.common.annotations.UnstableReactNativeAPI
import com.facebook.react.defaults.DefaultComponentsRegistry
import com.facebook.react.defaults.DefaultTurboModuleManagerDelegate
import com.facebook.react.fabric.ComponentFactory
import com.facebook.react.interfaces.fabric.ReactSurface
import com.facebook.react.runtime.ReactHostDelegate
import com.facebook.react.runtime.ReactHostImpl
import com.facebook.react.runtime.hermes.HermesInstance

@OptIn(UnstableReactNativeAPI::class, FrameworkAPI::class)
internal class Runtime private constructor(
  private val application: Application,
  private val bundleFilePath: String,
  private val logger: ComergeRuntimeLogger,
) {
  var host: ReactHost? = null
    private set

  var surface: ReactSurface? = null
    private set

  fun ensureHostCreated(): ReactHost {
    val existing = host
    if (existing != null) return existing

    val packages: List<ReactPackage> = getAppReactPackages(application)
    if (packages.isEmpty()) {
      logger.d(
        ComergeRuntimeContracts.TAG,
        "Runtime.ensureHostCreated: no React packages found from application (not a ReactApplication?)"
      )
    }

    val delegate = object : ReactHostDelegate {
      override val bindingsInstaller: com.facebook.react.runtime.BindingsInstaller? = null
      override val turboModuleManagerDelegateBuilder: ReactPackageTurboModuleManagerDelegate.Builder =
        DefaultTurboModuleManagerDelegate.Builder()
      override val jsBundleLoader: JSBundleLoader = JSBundleLoader.createFileLoader(bundleFilePath)
      override val jsMainModulePath: String = ComergeRuntimeContracts.JS_MAIN_MODULE_PATH
      override val jsRuntimeFactory: com.facebook.react.runtime.JSRuntimeFactory = HermesInstance()
      override val reactPackages: List<ReactPackage> = packages
      override fun handleInstanceException(error: Exception) {
        logger.e(ComergeRuntimeContracts.TAG, "Micro host instance exception", error)
      }
    }

    val componentFactory = ComponentFactory()
    DefaultComponentsRegistry.register(componentFactory)

    val created = ReactHostImpl(
      application,
      delegate,
      componentFactory,
      ComergeRuntimeContracts.ALLOW_PACKAGER_SERVER_ACCESS,
      ComergeRuntimeContracts.USE_DEV_SUPPORT,
    )

    host = created
    logger.d(ComergeRuntimeContracts.TAG, "ReactHostImpl created for micro app")
    return created
  }

  private fun getAppReactPackages(application: Application): List<ReactPackage> {
    try {
      val provided = (application as? ComergeRuntimePackagesProvider)?.getReactPackages()
      if (!provided.isNullOrEmpty()) {
        return provided
      }
    } catch (_: Throwable) {
      
    }

    val reactApplication = application as? ReactApplication ?: return emptyList()
    val host = reactApplication.reactNativeHost

    // `ReactNativeHost#getPackages()` is protected, so we need reflection to access the list
    // from a library module. The consuming app (Expo prebuild) still owns autolinking.
    return try {
      // IMPORTANT:
      // In Expo dev-client / prebuild setups, `reactNativeHost` is often a wrapper class
      // (e.g. `ReactNativeHostWrapper`) which may *not* declare `getPackages()` directly.
      // Reflecting on `host.javaClass` using `getDeclaredMethod` can fail and return an empty list,
      // which breaks core TurboModules (e.g. AppState).
      //
      // Reflect on the base type instead; invocation will still dispatch to the override.
      val m = ReactNativeHost::class.java.getDeclaredMethod("getPackages")
      m.isAccessible = true
      @Suppress("UNCHECKED_CAST")
      (m.invoke(host) as? List<ReactPackage>) ?: emptyList()
    } catch (_: Throwable) {
      emptyList()
    }
  }

  /**
   * Starts host initialization early (bundle load begins), but does not start the surface.
   */
  fun startHostEagerly() {
    try {
      ensureHostCreated().start()
    } catch (_: Throwable) {}
  }

  fun addOnContextInitializedListener(onReady: (ReactContext) -> Unit) {
    val h = host ?: return
    val listener = object : ReactInstanceEventListener {
      override fun onReactContextInitialized(context: ReactContext) {
        onReady(context)
        try {
          h.removeReactInstanceEventListener(this)
        } catch (_: Throwable) {}
      }
    }
    try {
      h.addReactInstanceEventListener(listener)
    } catch (_: Throwable) {}
  }

  fun getOrCreateSurface(activity: Activity, appKey: String, props: Bundle): ReactSurface {
    val h = ensureHostCreated()

    val existing = surface
    if (existing != null) {
      return existing
    }

    val created = h.createSurface(activity, appKey, props)
    surface = created
    return created
  }

  /**
   * Attempts to update init props on an existing surface
   * Safe no-op on RN versions where this isn't supported.
   */
  fun tryUpdateSurfaceInitProps(props: Bundle) {
    try {
      (surface as? com.facebook.react.runtime.ReactSurfaceImpl)?.updateInitProps(props)
    } catch (_: Throwable) {}
  }

  fun onHostResume(activity: Activity?) {
    try {
      host?.onHostResume(activity)
    } catch (_: Throwable) {}
  }

  fun onHostPause(activity: Activity?) {
    try {
      host?.onHostPause(activity)
    } catch (_: Throwable) {}
  }

  fun onHostDestroy(activity: Activity?) {
    try {
      host?.onHostDestroy(activity)
    } catch (_: Throwable) {}
  }

  fun destroy(reason: String) {
    try {
      surface?.stop()
    } catch (_: Throwable) {}
    try {
      surface?.clear()
    } catch (_: Throwable) {}
    try {
      surface?.detach()
    } catch (_: Throwable) {}
    surface = null

    try {
      host?.destroy(reason, null)
    } catch (_: Throwable) {}
    host = null
  }

  companion object {
    fun create(
      application: Application,
      bundleFilePath: String,
      logger: ComergeRuntimeLogger = ComergeRuntimeLoggers.ANDROID_LOGCAT
    ): Runtime {
      return Runtime(application, bundleFilePath, logger)
    }
  }
}


