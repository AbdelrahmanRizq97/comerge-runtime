import type { StyleProp, ViewProps, ViewStyle } from 'react-native';

export type ComergeRuntimeInitialProps = Record<string, unknown>;

export type ComergeRuntimeBridgeSource = 'host' | 'micro';

export type ComergeRuntimeBridgeEnvelope<TType extends string = string, TPayload = unknown> = {
  v: 1;
  type: TType;
  requestId: string;
  ts: number;
  source: ComergeRuntimeBridgeSource;
  payload?: TPayload;
  runtimeId?: string;
};

export type ComergeRuntimeSystemEventType =
  | 'system.auth_get_token'
  | 'system.auth_step_up_google'
  | 'system.open_app_requested'
  | 'system.open_shell_settings_requested'
  | 'system.sign_out_requested'
  | 'system.account_deleted'
  | 'system.session_invalid';

export type ComergeRuntimeSystemEventPayload = {
  requestId?: string;
  reason?: string;
  source?: string;
  appId?: string;
  appKey?: string;
  threadId?: string;
};

export type ComergeRuntimeSystemEventEnvelope = ComergeRuntimeBridgeEnvelope<
  ComergeRuntimeSystemEventType,
  ComergeRuntimeSystemEventPayload
>;

export type ComergeRuntimeViewMessageEvent = {
  envelope: ComergeRuntimeBridgeEnvelope;
};

export type ComergeRuntimeViewProps = ViewProps & {
  appKey: string;
  bundlePath: string;
  runtimeId?: string;
  initialProps?: ComergeRuntimeInitialProps;
  onMessage?: (event: ComergeRuntimeViewMessageEvent) => void;
  style?: StyleProp<ViewStyle>;
};
