import { requireNativeView } from 'expo';
import * as React from 'react';

import { ComergeRuntimeViewProps } from './ComergeRuntime.types';

const NativeView: React.ComponentType<ComergeRuntimeViewProps> = requireNativeView('ComergeRuntime');

export function ComergeRuntimeRenderer(props: ComergeRuntimeViewProps) {
  const { style, initialProps, ...rest } = props;
  const mergedStyle = React.useMemo(
    () => [{ flex: 1, alignSelf: 'stretch' }, style] as unknown as ComergeRuntimeViewProps['style'],
    [style]
  );

  return (
    <NativeView
      {...rest}
      initialProps={initialProps ?? {}}
      style={mergedStyle}
      collapsable={false}
    />
  );
}

export default ComergeRuntimeRenderer;
