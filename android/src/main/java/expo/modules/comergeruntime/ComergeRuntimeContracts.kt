package expo.modules.comergeruntime

internal object ComergeRuntimeContracts {
  const val TAG: String = "ComergeRuntime"
  const val JS_MAIN_MODULE_PATH: String = "index"
  const val MAX_BRIDGE_PAYLOAD_CHARS: Int = 64 * 1024

  const val ALLOW_PACKAGER_SERVER_ACCESS: Boolean = false
  const val USE_DEV_SUPPORT: Boolean = false

  val ALLOWED_SYSTEM_EVENT_TYPES = setOf(
    "system.auth_get_token",
    "system.auth_step_up_google",
    "system.open_app_requested",
    "system.open_shell_settings_requested",
    "system.sign_out_requested",
    "system.account_deleted",
    "system.session_invalid",
  )
}


