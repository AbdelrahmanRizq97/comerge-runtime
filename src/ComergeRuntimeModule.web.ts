import { registerWebModule, NativeModule } from 'expo';

import { ComergeRuntimeModuleEvents } from './ComergeRuntime.types';

class ComergeRuntimeModule extends NativeModule<ComergeRuntimeModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(ComergeRuntimeModule, 'ComergeRuntimeModule');
