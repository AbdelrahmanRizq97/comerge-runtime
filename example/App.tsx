import { SafeAreaView, ScrollView, Text, View } from 'react-native';
import { MicroAppHost } from '@comerge/runtime';

export default function App() {
  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.container}>
        <Text style={styles.header}>Comerge Runtime (Micro App Host)</Text>
        <Group name="MicroAppHost">
          <Text style={{ marginBottom: 12 }}>
            Provide a local JS bundle file path (on device) to render a micro-app.
          </Text>
          <MicroAppHost
            // Example defaults - you must provide a real on-device bundle path for this to render.
            appKey="MicroMain"
            bundlePath=""
            initialProps={{}}
            style={styles.view}
          />
        </Group>
      </ScrollView>
    </SafeAreaView>
  );
}

function Group(props: { name: string; children: React.ReactNode }) {
  return (
    <View style={styles.group}>
      <Text style={styles.groupHeader}>{props.name}</Text>
      {props.children}
    </View>
  );
}

const styles = {
  header: {
    fontSize: 30,
    margin: 20,
  },
  groupHeader: {
    fontSize: 20,
    marginBottom: 20,
  },
  group: {
    margin: 20,
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 20,
  },
  container: {
    flex: 1,
    backgroundColor: '#eee',
  },
  view: {
    flex: 1,
    height: 200,
  },
};
