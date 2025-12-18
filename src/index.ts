// Reexport the native module. On web, it will be resolved to ComergeRuntimeModule.web.ts
// and on native platforms to ComergeRuntimeModule.ts
export { default } from './ComergeRuntimeModule';
export { default as ComergeRuntimeView } from './ComergeRuntimeView';
export * from  './ComergeRuntime.types';
