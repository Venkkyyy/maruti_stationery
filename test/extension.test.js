const test = require('node:test');
const assert = require('node:assert/strict');
const extension = require('../extension');

test('parseAndroidAvdOutput parses newline separated AVD names', () => {
  const parsed = extension.parseAndroidAvdOutput('Pixel_7_API_34\nNexus_6P\n');
  assert.deepEqual(parsed, ['Pixel_7_API_34', 'Nexus_6P']);
});

test('parseIOSDeviceOutput parses simulator JSON', () => {
  const parsed = extension.parseIOSDeviceOutput(JSON.stringify({
    devices: {
      'com.apple.CoreSimulator.SimRuntime.iOS-17-5': [
        { name: 'iPhone 15', udid: '123', isAvailable: true },
      ],
    },
  }));

  assert.equal(parsed[0].label, 'iPhone 15 (com.apple.CoreSimulator.SimRuntime.iOS-17-5)');
  assert.equal(parsed[0].udid, '123');
});

test('resolveAndroidEmulatorPath resolves a configured directory to the executable', async () => {
  const config = {
    get(name) {
      const values = {
        emulatorPath: '~/Library/Android/sdk/emulator',
        emulatorPathWindows: 'C:/Android/emulator',
      };
      return values[name];
    },
  };

  const resolved = await extension.resolveAndroidEmulatorPath(config);
  assert.match(resolved, /emulator(\.exe)?$/i);
});

test('resolveSimulatorPath returns configured path when provided', async () => {
  const config = {
    get(name) {
      if (name === 'simulatorPath') {
        return '/Applications/Simulator.app';
      }
      return '';
    },
  };

  const resolved = await extension.resolveSimulatorPath(config);
  assert.equal(resolved, '/Applications/Simulator.app');
});
