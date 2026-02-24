import { requireNativeView } from 'expo';
import * as React from 'react';

import type { ComergeRuntimeBridgeEnvelope, ComergeRuntimeViewProps } from './ComergeRuntime.types';

const NativeView: React.ComponentType<any> = requireNativeView('ComergeRuntime');

export function ComergeRuntimeRenderer(props: ComergeRuntimeViewProps) {
  const { style, initialProps, onMessage, ...rest } = props;
  const mergedStyle = React.useMemo(
    () => [{ flex: 1, alignSelf: 'stretch' }, style] as unknown as ComergeRuntimeViewProps['style'],
    [style]
  );
  const handleNativeMessage = React.useCallback(
    (event: { nativeEvent?: { envelope?: ComergeRuntimeBridgeEnvelope } }) => {
      const envelope = event?.nativeEvent?.envelope;
      if (!envelope || typeof envelope !== 'object') return;
      onMessage?.({ envelope });
    },
    [onMessage]
  );

  return (
    <NativeView
      {...rest}
      initialProps={initialProps ?? {}}
      onMessage={handleNativeMessage}
      style={mergedStyle}
      collapsable={false}
    />
  );
}

export default ComergeRuntimeRenderer;
