package expo.modules.comergeruntime

import android.util.Log

internal fun interface ComergeRuntimeLogger {
  fun d(tag: String, message: String)
}

internal object ComergeRuntimeLoggers {
  val ANDROID_LOGCAT: ComergeRuntimeLogger = ComergeRuntimeLogger { tag, message -> Log.d(tag, message) }
}

internal fun ComergeRuntimeLogger.e(tag: String, message: String, t: Throwable? = null) {
  if (t == null) Log.e(tag, message) else Log.e(tag, message, t)
}


