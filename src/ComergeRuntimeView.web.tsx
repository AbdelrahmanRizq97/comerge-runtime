import * as React from 'react';

import { ComergeRuntimeViewProps } from './ComergeRuntime.types';

export default function ComergeRuntimeView(props: ComergeRuntimeViewProps) {
  return (
    <div>
      <div style={{ padding: 12, fontFamily: 'system-ui, sans-serif' }}>
        ComergeRuntimeView is not supported on web. (Received appKey=&quot;{props.appKey}&quot;)
      </div>
    </div>
  );
}
