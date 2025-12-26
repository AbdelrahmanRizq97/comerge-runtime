package expo.modules.comergeruntime

import android.content.Context
import android.os.Bundle
import android.view.View
import android.view.View.MeasureSpec
import android.view.ViewGroup
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.LifecycleEventListener
import com.facebook.react.bridge.ReactApplicationContext
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.views.ExpoView
import com.facebook.react.common.annotations.FrameworkAPI
import com.facebook.react.common.annotations.UnstableReactNativeAPI


@OptIn(UnstableReactNativeAPI::class, FrameworkAPI::class)
class ComergeRuntimeView(
  context: Context,
  appContext: AppContext
) : ExpoView(context, appContext), LifecycleEventListener {
  private val logger: ComergeRuntimeLogger = ComergeRuntimeLoggers.ANDROID_LOGCAT

  private val reactAppContext: ReactApplicationContext? =
    appContext.reactContext as? ReactApplicationContext

  // Inputs from React props
  private var appKey: String? = null
  private var bundlePath: String? = null
  private var initialProps: Map<String, Any?>? = null

  // Runtime objects
  private var runtime: Runtime? = null

  // Start gates / state
  // Generation token to ignore delayed callbacks from previous loads after an unload/reload.
  private var loadGeneration: Int = 0
  private var started: Boolean = false
  private var starting: Boolean = false
  private var contextInitialized: Boolean = false
  private var hasNonZeroSize: Boolean = false

  init {
    reactAppContext?.addLifecycleEventListener(this)
    layoutParams = LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
  }

  fun setAppKey(value: String?) {
    if (appKey == value) return
    appKey = value
    // If a runtime already exists, unload so the new appKey can take effect.
    if (runtime != null) {
      unloadMicroApp()
    }
    maybeLoadMicroApp()
  }

  fun setBundlePath(value: String?) {
    val next = value?.removePrefix("file://")
    if (bundlePath == next) return
    bundlePath = next
    // If a runtime already exists, unload so the new bundlePath can take effect.
    if (runtime != null) {
      unloadMicroApp()
    }
    maybeLoadMicroApp()
  }

  fun setInitialProps(value: Map<String, Any?>?) {
    initialProps = value

    // if a surface exists (micro app already created), reload to apply new props.
    if (runtime?.surface != null && runtime?.host != null && appKey != null) {
      unloadMicroApp()
      maybeLoadMicroApp()
    }
  }

  private fun maybeLoadMicroApp() {
    val key = appKey
    val path = bundlePath
    if (key.isNullOrBlank() || path.isNullOrBlank()) return

    // do nothing if runtime already exists.
    if (runtime?.host != null) return

    try {
      logger.d(ComergeRuntimeContracts.TAG, "maybeLoadMicroApp: appKey=$key path=$path")

      val app = context.applicationContext as android.app.Application
      val r = Runtime.create(app, path, logger)
      runtime = r
      val gen = loadGeneration

      r.ensureHostCreated()

      // Begin loading the instance early; we'll start the surface after context init.
      r.startHostEagerly()

      // Wait for React context to initialize (bundle executed, modules registered) then start.
      r.addOnContextInitializedListener {
        if (gen != loadGeneration || runtime !== r) return@addOnContextInitializedListener
        logger.d(ComergeRuntimeContracts.TAG, "onReactContextInitialized for micro app (ReactHost)")
        contextInitialized = true
        postDelayed({
          if (gen != loadGeneration || runtime !== r) return@postDelayed
          logger.d(ComergeRuntimeContracts.TAG, "onReactContextInitialized: attempting start after delay")
          tryStartIfPossible()
        }, 300)
      }
    } catch (t: Throwable) {
      logger.e(ComergeRuntimeContracts.TAG, "Failed to load micro app: appKey=$key path=$path", t)
    }
  }

  private fun createInitialPropsBundle(): Bundle {
    val map = initialProps ?: emptyMap()
    return try {
      @Suppress("UNCHECKED_CAST")
      val nativeMap = Arguments.makeNativeMap(map as Map<String, Any>)
      Arguments.toBundle(nativeMap) ?: Bundle()
    } catch (_: Throwable) {
      Bundle()
    }
  }

  private fun tryStartIfPossible() {
    if (started) {
      logger.d(ComergeRuntimeContracts.TAG, "tryStartIfPossible: already started")
      return
    }
    if (starting) {
      logger.d(ComergeRuntimeContracts.TAG, "tryStartIfPossible: already starting")
      return
    }
    if (!contextInitialized) {
      logger.d(ComergeRuntimeContracts.TAG, "tryStartIfPossible: context not initialized yet")
      return
    }
    if (width == 0 || height == 0) {
      logger.d(ComergeRuntimeContracts.TAG, "tryStartIfPossible: container size is 0x0")
      return
    }

    val r = runtime
    val host = r?.host
    if (r == null || host == null) {
      logger.d(ComergeRuntimeContracts.TAG, "tryStartIfPossible: reactHost null")
      return
    }

    val key = appKey
    if (key.isNullOrBlank()) {
      logger.d(ComergeRuntimeContracts.TAG, "tryStartIfPossible: appKey null/blank")
      return
    }

    val activityRef = appContext.currentActivity
    if (activityRef == null) {
      logger.d(ComergeRuntimeContracts.TAG, "tryStartIfPossible: currentActivity null")
      return
    }

    // All prerequisites satisfied; start on UI thread.
    val gen = loadGeneration
    starting = true
    post {
      if (gen != loadGeneration || runtime !== r) {
        starting = false
        return@post
      }
      try {
        val props = createInitialPropsBundle()

        // call start again defensively (no-op if already started).
        try {
          host.start()
        } catch (_: Throwable) {}

        val surface = r.getOrCreateSurface(activityRef, key, props)
        val view = surface.view
        if (view != null) {
          attachSurfaceView(view)
        }

        // if surface already exists, attempt to update init props.
        r.tryUpdateSurfaceInitProps(props)

        surface.start()
        started = true

        r.onHostResume(activityRef)
        logger.d(ComergeRuntimeContracts.TAG, "Started React application appKey=$key (attached and resumed)")
      } catch (t: Throwable) {
        logger.e(ComergeRuntimeContracts.TAG, "Failed to start React app (tryStartIfPossible)", t)
      } finally {
        starting = false
      }
    }
  }

  private fun attachSurfaceView(view: View) {
    removeAllViews()
    addView(view, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))

    try {
      // Force immediate measure/layout to fill this container if we already have size.
      val w = width
      val h = height
      if (w > 0 && h > 0) {
        val wSpec = MeasureSpec.makeMeasureSpec(w, MeasureSpec.EXACTLY)
        val hSpec = MeasureSpec.makeMeasureSpec(h, MeasureSpec.EXACTLY)
        view.measure(wSpec, hSpec)
        view.layout(0, 0, w, h)
        logger.d(ComergeRuntimeContracts.TAG, "Immediately laid out surface view size=${view.measuredWidth}x${view.measuredHeight}")
      }
      view.bringToFront()
      view.requestLayout()
      requestLayout()
      invalidate()
      logger.d(ComergeRuntimeContracts.TAG, "Attached surface view size=${view.width}x${view.height}")
    } catch (_: Throwable) {}
  }

  private fun unloadMicroApp() {
    // Invalidate any in-flight callbacks from the currently loading/starting runtime.
    loadGeneration += 1
    removeAllViews()
    try {
      runtime?.destroy("unloadMicroApp")
    } catch (_: Throwable) {}
    runtime = null

    started = false
    starting = false
    contextInitialized = false
    hasNonZeroSize = false
  }

  override fun onHostResume() {
    runtime?.onHostResume(appContext.currentActivity)
    tryStartIfPossible()
  }

  override fun onHostPause() {
    runtime?.onHostPause(appContext.currentActivity)
  }

  override fun onHostDestroy() {
    runtime?.onHostDestroy(appContext.currentActivity)
    unloadMicroApp()
    reactAppContext?.removeLifecycleEventListener(this)
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    tryStartIfPossible()
  }

  override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
    super.onSizeChanged(w, h, oldw, oldh)
    val nonZero = w > 0 && h > 0
    if (nonZero && !hasNonZeroSize) {
      hasNonZeroSize = true
      logger.d(ComergeRuntimeContracts.TAG, "Container size now non-zero: ${w}x${h}")
      tryStartIfPossible()
    }
  }

  override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
    super.onLayout(changed, left, top, right, bottom)
    if (childCount > 0) {
      val child: View = getChildAt(0)
      val w = right - left
      val h = bottom - top
      val wSpec = MeasureSpec.makeMeasureSpec(w, MeasureSpec.EXACTLY)
      val hSpec = MeasureSpec.makeMeasureSpec(h, MeasureSpec.EXACTLY)
      child.measure(wSpec, hSpec)
      child.layout(0, 0, w, h)
      logger.d(ComergeRuntimeContracts.TAG, "Laid out child to size=${child.measuredWidth}x${child.measuredHeight}")

      // start when we finally have a sized child.
      if (!started && contextInitialized && runtime?.surface != null && child.measuredWidth > 0 && child.measuredHeight > 0) {
        try {
          runtime?.surface?.start()
          started = true
          logger.d(ComergeRuntimeContracts.TAG, "Started surface from onLayout after sizing")
        } catch (_: Throwable) {}
      }
    }
  }
}
