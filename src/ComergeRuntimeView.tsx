import { requireNativeView } from 'expo';
import * as React from 'react';

import { ComergeRuntimeViewProps } from './ComergeRuntime.types';

const NativeView: React.ComponentType<ComergeRuntimeViewProps> =
  requireNativeView('ComergeRuntime');

export default function ComergeRuntimeView(props: ComergeRuntimeViewProps) {
  return <NativeView {...props} />;
}
