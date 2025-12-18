import { NativeModule, requireNativeModule } from 'expo';

import { ComergeRuntimeModuleEvents } from './ComergeRuntime.types';

declare class ComergeRuntimeModule extends NativeModule<ComergeRuntimeModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ComergeRuntimeModule>('ComergeRuntime');
