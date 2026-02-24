import { NativeModule, requireNativeModule } from 'expo';
import type { EventSubscription } from 'expo-modules-core';
import type { ComergeRuntimeBridgeEnvelope } from './ComergeRuntime.types';

type ComergeRuntimeModuleEvents = {
  onRuntimeMessage: (event: {
    envelope: ComergeRuntimeBridgeEnvelope;
  }) => void;
};

declare class ComergeRuntimeModule extends NativeModule<ComergeRuntimeModuleEvents> {
  postMessageToRuntime(envelope: ComergeRuntimeBridgeEnvelope): boolean;
  emitSystemEvent(envelope: ComergeRuntimeBridgeEnvelope): boolean;
  addListener<EventName extends keyof ComergeRuntimeModuleEvents>(eventName: EventName, listener: ComergeRuntimeModuleEvents[EventName]): EventSubscription;
}

export default requireNativeModule<ComergeRuntimeModule>('ComergeRuntime');
