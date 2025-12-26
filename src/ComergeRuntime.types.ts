import type { StyleProp, ViewProps, ViewStyle } from 'react-native';

export type ComergeRuntimeInitialProps = Record<string, unknown>;

export type ComergeRuntimeViewProps = ViewProps & {
  appKey: string;
  bundlePath: string;
  initialProps?: ComergeRuntimeInitialProps;
  style?: StyleProp<ViewStyle>;
};
