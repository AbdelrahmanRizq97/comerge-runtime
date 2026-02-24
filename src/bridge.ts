import ComergeRuntimeModule from './ComergeRuntimeModule';
import type {
  ComergeRuntimeBridgeEnvelope,
  ComergeRuntimeSystemEventEnvelope,
  ComergeRuntimeSystemEventPayload,
  ComergeRuntimeSystemEventType,
} from './ComergeRuntime.types';
import type { EventSubscription } from 'expo-modules-core';
import { DeviceEventEmitter, Platform } from 'react-native';

function randomId(): string {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
}

export function createBridgeEnvelope<TType extends string, TPayload>(
  type: TType,
  payload?: TPayload,
  source: 'host' | 'micro' = 'micro',
  runtimeId?: string
): ComergeRuntimeBridgeEnvelope<TType, TPayload> {
  return {
    v: 1,
    type,
    requestId: randomId(),
    ts: Date.now(),
    source,
    payload,
    runtimeId,
  };
}

export function emitSystemEvent(
  type: ComergeRuntimeSystemEventType,
  payload?: ComergeRuntimeSystemEventPayload,
  runtimeId?: string
): boolean {
  const envelope = createBridgeEnvelope(type, payload, 'micro', runtimeId);
  return Boolean(ComergeRuntimeModule.emitSystemEvent(envelope));
}

export function postMessageToRuntime<TPayload = unknown>(
  type: string,
  payload?: TPayload,
  runtimeId?: string
): boolean {
  const envelope = createBridgeEnvelope(type, payload, 'host', runtimeId);
  return Boolean(ComergeRuntimeModule.postMessageToRuntime(envelope));
}

export function isBridgeEnvelope(value: unknown): value is ComergeRuntimeBridgeEnvelope {
  if (!value || typeof value !== 'object') return false;
  const candidate = value as Partial<ComergeRuntimeBridgeEnvelope>;
  return (
    candidate.v === 1 &&
    typeof candidate.type === 'string' &&
    typeof candidate.requestId === 'string' &&
    typeof candidate.ts === 'number' &&
    (candidate.source === 'host' || candidate.source === 'micro')
  );
}

export function isSystemEventEnvelope(value: unknown): value is ComergeRuntimeSystemEventEnvelope {
  if (!isBridgeEnvelope(value)) return false;
  return (
    value.type === 'system.auth_get_token' ||
    value.type === 'system.auth_step_up_google' ||
    value.type === 'system.open_app_requested' ||
    value.type === 'system.sign_out_requested' ||
    value.type === 'system.account_deleted' ||
    value.type === 'system.session_invalid'
  );
}

export function addRuntimeMessageListener(
  listener: (envelope: ComergeRuntimeBridgeEnvelope) => void
): EventSubscription {
  if (Platform.OS === 'android') {
    const sub = DeviceEventEmitter.addListener('onRuntimeMessage', (event: { envelope?: unknown }) => {
      if (!isBridgeEnvelope(event?.envelope)) return;
      listener(event.envelope);
    });
    return {
      remove: () => sub.remove(),
    } as EventSubscription;
  }

  return ComergeRuntimeModule.addListener('onRuntimeMessage', (event) => {
    if (!isBridgeEnvelope(event?.envelope)) return;
    listener(event.envelope);
  });
}
