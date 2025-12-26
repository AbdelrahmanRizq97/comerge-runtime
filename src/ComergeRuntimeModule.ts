import { NativeModule, requireNativeModule } from 'expo';

type ComergeRuntimeModuleEvents = Record<string, never>;

declare class ComergeRuntimeModule extends NativeModule<ComergeRuntimeModuleEvents> {}

export default requireNativeModule<ComergeRuntimeModule>('ComergeRuntime');
