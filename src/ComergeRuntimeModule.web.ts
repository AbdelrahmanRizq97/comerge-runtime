import { registerWebModule, NativeModule } from 'expo';

type ComergeRuntimeModuleEvents = Record<string, never>;

class ComergeRuntimeModule extends NativeModule<ComergeRuntimeModuleEvents> {}

export default registerWebModule(ComergeRuntimeModule, 'ComergeRuntimeModule');
