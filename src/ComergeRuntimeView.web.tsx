import * as React from 'react';

import { ComergeRuntimeViewProps } from './ComergeRuntime.types';

export default function ComergeRuntimeView(props: ComergeRuntimeViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
