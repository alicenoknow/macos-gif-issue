// Minimal JS repro for react-native-macos: an animated GIF stays on its first frame.
// Drop this in as App.tsx of a fresh react-native-macos app (Fabric or Paper; both are affected).
import React from 'react';
import {Image, Text, View} from 'react-native';

// Any multi-frame GIF works. This is the same GIF RNTester uses for its "Animated GIF" example.
const GIF = {
  uri: 'https://raw.githubusercontent.com/microsoft/react-native-macos/main/packages/rn-tester/js/assets/tumblr_mfqekpMktw1rn90umo1_500.gif',
};

export default function App() {
  const [loaded, setLoaded] = React.useState(false);
  return (
    <View style={{flex: 1, alignItems: 'center', justifyContent: 'center', gap: 12}}>
      <Image source={GIF} style={{width: 200, height: 200}} onLoad={() => setLoaded(true)} />
      <Text>onLoad fired: {String(loaded)}. Expected: animating. Actual: frozen on frame 0.</Text>
    </View>
  );
}
