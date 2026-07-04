const cp = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

let vscode;
try {
  vscode = require('vscode');
} catch (error) {
  vscode = null;
}

function expandPath(value) {
  if (!value) {
    return '';
  }

  let expanded = value.trim().replace(/^['"]|['"]$/g, '');
  if (!expanded) {
    return '';
  }

  if (expanded.startsWith('~')) {
    expanded = path.join(os.homedir(), expanded.slice(1));
  }

  expanded = expanded.replace(/%([A-Za-z0-9_]+)%/g, (_match, name) => process.env[name] || '');
  return expanded;
}

function getAndroidEmulatorCandidates(configuration) {
  const platform = process.platform;
  const candidates = [];
  const addCandidate = (value) => {
    if (!value) {
      return;
    }

    const expanded = expandPath(value);
    if (!expanded) {
      return;
    }

    const normalized = expanded.replace(/\\/g, '/');
    if (!candidates.includes(normalized)) {
      candidates.push(normalized);
    }
  };

  if (configuration && typeof configuration.get === 'function') {
    const fallback = configuration.get('emulatorPath') || '';
    if (platform === 'win32') {
      addCandidate(configuration.get('emulatorPathWindows') || fallback);
    } else if (platform === 'darwin') {
      addCandidate(configuration.get('emulatorPathMac') || fallback);
    } else if (platform === 'linux') {
      const isWsl = /microsoft/i.test(process.env.WSL_DISTRO_NAME || '') || /microsoft/i.test(process.env.WINDIR || '');
      if (isWsl) {
        addCandidate(configuration.get('emulatorPathWSL') || configuration.get('emulatorPathLinux') || fallback);
      } else {
        addCandidate(configuration.get('emulatorPathLinux') || fallback);
      }
    } else {
      addCandidate(fallback);
    }
  }

  const envEntries = [
    process.env.ANDROID_SDK_ROOT,
    process.env.ANDROID_HOME,
    process.env.ANDROID_SDK,
  ].filter(Boolean);

  envEntries.forEach((entry) => addCandidate(entry));

  if (platform === 'win32') {
    addCandidate(path.join(process.env.LOCALAPPDATA || '', 'Android', 'Sdk', 'emulator'));
    addCandidate(path.join(process.env.USERPROFILE || '', 'AppData', 'Local', 'Android', 'Sdk', 'emulator'));
  } else if (platform === 'darwin') {
    addCandidate(path.join(os.homedir(), 'Library', 'Android', 'sdk', 'emulator'));
  } else {
    addCandidate(path.join(os.homedir(), 'Android', 'Sdk', 'emulator'));
    addCandidate(path.join(os.homedir(), 'Android', 'sdk', 'emulator'));
  }

  const commonPaths = [
    '/opt/android-sdk/emulator',
    '/usr/local/share/android-sdk/emulator',
    '/usr/lib/android-sdk/emulator',
  ];

  commonPaths.forEach((entry) => addCandidate(entry));

  return candidates;
}

function resolveAndroidEmulatorPath(configuration) {
  return new Promise((resolve) => {
    const candidates = getAndroidEmulatorCandidates(configuration);
    const checkedPaths = [];

    const addAlternatives = (basePath) => {
      if (!basePath) {
        return;
      }

      const normalized = basePath.replace(/\\/g, '/');
      const trimmed = normalized.trim();
      if (!trimmed) {
        return;
      }

      const suffixes = [
        trimmed,
        `${trimmed}/emulator`,
        `${trimmed}/emulator.exe`,
        `${trimmed}/emulator/emulator`,
        `${trimmed}/emulator/emulator.exe`,
        `${trimmed}/tools/emulator`,
        `${trimmed}/tools/emulator.exe`,
      ];

      suffixes.forEach((candidate) => {
        if (!checkedPaths.includes(candidate)) {
          checkedPaths.push(candidate);
        }
      });
    };

    candidates.forEach(addAlternatives);

    const resolved = checkedPaths.find((candidate) => fs.existsSync(candidate));
    if (resolved) {
      resolve(resolved);
      return;
    }

    if (process.platform === 'win32') {
      resolve(path.join(process.env.LOCALAPPDATA || '', 'Android', 'Sdk', 'emulator', 'emulator.exe'));
      return;
    }

    resolve('');
  });
}

function resolveSimulatorPath(configuration) {
  return new Promise((resolve) => {
    if (!configuration || typeof configuration.get !== 'function') {
      resolve('/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app');
      return;
    }

    const configuredPath = configuration.get('simulatorPath');
    if (configuredPath && configuredPath.trim()) {
      resolve(configuredPath.trim());
      return;
    }

    if (process.platform !== 'darwin') {
      resolve('/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app');
      return;
    }

    cp.execFile('xcode-select', ['-p'], { encoding: 'utf8' }, (error, stdout) => {
      if (error) {
        resolve('/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app');
        return;
      }

      const developerPath = stdout.trim();
      const candidates = [
        `${developerPath}/Applications/Simulator.app`,
        '/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app',
      ];

      const existing = candidates.find((candidate) => candidate && candidate.length > 0);
      resolve(existing || '/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app');
    });
  });
}

function parseAndroidAvdOutput(output) {
  return output
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
}

function parseIOSDeviceOutput(output) {
  const data = JSON.parse(output);
  const results = [];

  for (const [runtimeName, devices] of Object.entries(data.devices || {})) {
    for (const device of devices || []) {
      if (device.isAvailable === false) {
        continue;
      }

      results.push({
        label: `${device.name} (${runtimeName})`,
        detail: device.udid,
        runtime: runtimeName,
        udid: device.udid,
        kind: 'ios',
      });
    }
  }

  return results;
}

function listAndroidAvds(emulatorPath) {
  return new Promise((resolve) => {
    if (!emulatorPath) {
      resolve([]);
      return;
    }

    cp.execFile(emulatorPath, ['-list-avds'], { encoding: 'utf8' }, (error, stdout) => {
      if (error) {
        resolve([]);
        return;
      }

      const avds = parseAndroidAvdOutput(stdout).map((name) => ({
        label: name,
        description: 'Android',
        kind: 'android',
        avdName: name,
      }));

      resolve(avds);
    });
  });
}

function listIOSSimulators() {
  return new Promise((resolve) => {
    if (process.platform !== 'darwin') {
      resolve([]);
      return;
    }

    cp.execFile('xcrun', ['simctl', 'list', 'devices', 'available', '--json'], { encoding: 'utf8' }, (error, stdout) => {
      if (error) {
        resolve([]);
        return;
      }

      try {
        resolve(parseIOSDeviceOutput(stdout));
      } catch (parseError) {
        resolve([]);
      }
    });
  });
}

async function getAvailableDevices(configuration) {
  const emulatorPath = await resolveAndroidEmulatorPath(configuration);
  const [androidDevices, iosDevices] = await Promise.all([
    listAndroidAvds(emulatorPath),
    listIOSSimulators(),
  ]);

  return [...androidDevices, ...iosDevices];
}

async function startAndroidEmulator(configuration, target) {
  const emulatorPath = await resolveAndroidEmulatorPath(configuration);
  const args = ['-avd', target.avdName];

  if (!emulatorPath) {
    if (vscode) {
      vscode.window.showErrorMessage('Unable to find the Android emulator executable. Update the emulator path in settings.');
    }
    return;
  }

  if (configuration && typeof configuration.get === 'function' && configuration.get('androidColdBoot')) {
    args.push('-no-snapshot-load');
  }

  const child = cp.spawn(emulatorPath, args, { stdio: 'inherit' });
  child.on('error', () => {
    if (vscode) {
      vscode.window.showErrorMessage(`Unable to launch ${target.avdName}. Check the emulator path in settings and ensure the Android SDK is installed.`);
    }
  });
}

function startIOSSimulator(configuration, target) {
  return new Promise(async (resolve, reject) => {
    const simulatorPath = await resolveSimulatorPath(configuration);

    cp.execFile('open', ['-a', simulatorPath], (openError) => {
      if (openError) {
        reject(openError);
        return;
      }

      cp.execFile('xcrun', ['simctl', 'boot', target.udid], (bootError) => {
        if (bootError) {
          reject(bootError);
          return;
        }

        resolve();
      });
    });
  });
}

async function runSelectedDevice(configuration, target) {
  if (!target) {
    return;
  }

  if (target.kind === 'android') {
    await startAndroidEmulator(configuration, target);
    return;
  }

  if (process.platform !== 'darwin') {
    if (vscode) {
      vscode.window.showWarningMessage('iOS simulators require macOS with Xcode installed.');
    }
    return;
  }

  try {
    await startIOSSimulator(configuration, target);
    if (vscode) {
      vscode.window.showInformationMessage(`Started ${target.label}`);
    }
  } catch (error) {
    if (vscode) {
      vscode.window.showErrorMessage(`Unable to start ${target.label}. ${error.message}`);
    }
  }
}

async function selectAndRun() {
  if (!vscode) {
    return;
  }

  const configuration = vscode.workspace.getConfiguration('emulator');
  const devices = await getAvailableDevices(configuration);

  if (!devices.length) {
    const hint = process.platform === 'win32'
      ? 'Set "emulator.emulatorPathWindows" to your Android SDK emulator folder, for example C:\\Users\\<you>\\AppData\\Local\\Android\\Sdk\\emulator.'
      : 'Set the emulator path in settings to the Android SDK emulator folder.';
    vscode.window.showInformationMessage(`No Android emulators or iOS simulators were found. ${hint}`);
    return;
  }

  const selected = await vscode.window.showQuickPick(devices.map((device) => ({
    label: device.label,
    description: device.description || (device.kind === 'ios' ? 'iOS' : 'Android'),
    detail: device.detail,
    kind: device.kind,
    avdName: device.avdName,
    udid: device.udid,
  })), {
    placeHolder: 'Select an emulator or simulator',
  });

  if (selected) {
    await runSelectedDevice(configuration, selected);
  }
}

function activate(context) {
  if (!vscode) {
    return;
  }

  const statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
  statusBarItem.text = '$(device-mobile) Emulator';
  statusBarItem.tooltip = 'Select and run an emulator or simulator';
  statusBarItem.command = 'emulator.run';
  statusBarItem.show();

  const command = vscode.commands.registerCommand('emulator.run', selectAndRun);
  context.subscriptions.push(statusBarItem, command);
}

function deactivate() {}

module.exports = {
  activate,
  deactivate,
  getAvailableDevices,
  parseAndroidAvdOutput,
  parseIOSDeviceOutput,
  resolveAndroidEmulatorPath,
  resolveSimulatorPath,
  selectAndRun,
};
