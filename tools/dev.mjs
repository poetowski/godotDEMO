#!/usr/bin/env node
// Dev commands for this Godot project, run through npm (see package.json):
//
//   npm run editor               open the project in the Godot editor
//   npm run game [-- <scene>]    play the game, or one scene, in a window
//   npm run import               import new or changed assets, headless
//   npm run check                import, then load every script, scene and
//                                resource in src/ data/ assets/ tests/ tools/
//   npm test [-- <gut args>]     run the GUT suite headless, e.g.
//                                npm test -- -gselect=test_fly_camera
//   npm run shot [-- <scene>] [--out=<png>] [--frames=<n>] [--size=<WxH>]
//                                play a scene in a window, save a PNG, quit
//   npm run api                  dump the engine's class reference to .godot-api/
//   npm run where                print the Godot binary in use
//
// The engine is pinned to GODOT_VERSION below. Set the GODOT environment
// variable to use another binary (on Windows, the *_console.exe one).

import { spawn } from 'node:child_process';
import { existsSync, mkdirSync, rmSync, statSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const GODOT_VERSION = '4.7.2';
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const ANSI = /\x1b\[[0-9;]*m/g;
const ERROR_LINE = /^\s*(SCRIPT ERROR|SHADER ERROR|USER ERROR|ERROR):/;
const WARNING_LINE = /^\s*(SCRIPT WARNING|USER WARNING|WARNING):/;

function godotBinary({ gui = false } = {}) {
  const fromEnv = process.env.GODOT;
  if (fromEnv) return gui ? fromEnv.replace(/_console\.exe$/i, '.exe') : fromEnv;
  if (process.platform === 'win32') {
    const dir = path.join(process.env.LOCALAPPDATA ?? '', 'Programs', 'Godot', GODOT_VERSION);
    const exe = path.join(dir, `Godot_v${GODOT_VERSION}-stable_win64${gui ? '' : '_console'}.exe`);
    if (existsSync(exe)) return exe;
  }
  return 'godot';
}

// Runs Godot, echoing its output, and resolves with the exit code, the output
// and the error and warning lines found in it.
function godot(args, { timeoutMs = 0 } = {}) {
  return new Promise((resolve) => {
    const child = spawn(godotBinary(), args, { cwd: ROOT, stdio: ['ignore', 'pipe', 'pipe'] });
    let output = '';
    const echo = (stream) => (chunk) => {
      const text = chunk.toString();
      output += text;
      stream.write(text);
    };
    child.stdout.on('data', echo(process.stdout));
    child.stderr.on('data', echo(process.stderr));
    const timer = timeoutMs
      ? setTimeout(() => {
          console.error(`\n[dev] Godot ran longer than ${timeoutMs / 1000}s; stopping it.`);
          child.kill();
        }, timeoutMs)
      : null;
    const finish = (code) => {
      if (timer) clearTimeout(timer);
      const lines = output.replace(ANSI, '').split(/\r?\n/);
      resolve({
        code,
        output,
        errors: lines.filter((line) => ERROR_LINE.test(line)),
        warnings: lines.filter((line) => WARNING_LINE.test(line)),
      });
    };
    child.on('error', (error) => {
      console.error(`[dev] could not start Godot (${godotBinary()}): ${error.message}`);
      finish(1);
    });
    child.on('close', (code) => finish(code ?? 1));
  });
}

function report(name, result) {
  const { code, errors, warnings } = result;
  console.log(`\n[dev] ${name}: exit ${code}, ${errors.length} error(s), ${warnings.length} warning(s)`);
  for (const line of errors) console.log(`  ${line.trim()}`);
  for (const line of warnings) console.log(`  ${line.trim()}`);
  return code === 0 && errors.length === 0;
}

// The editor caches imports and the class registry in .godot/; a fresh
// checkout has none, so import once before running anything headless.
async function ensureImported() {
  if (existsSync(path.join(ROOT, '.godot', 'uid_cache.bin'))) return true;
  console.log('[dev] .godot/ cache missing, importing first');
  return importAssets();
}

async function importAssets() {
  return report('import', await godot(['--headless', '--path', ROOT, '--import'], { timeoutMs: 15 * 60_000 }));
}

function toResPath(scene) {
  if (scene.startsWith('res://')) return scene;
  const relative = path.relative(ROOT, path.resolve(process.cwd(), scene)).split(path.sep).join('/');
  return `res://${relative}`;
}

function parseOptions(argv) {
  const options = {};
  const positional = [];
  for (const arg of argv) {
    const match = arg.match(/^--([a-z-]+)=(.*)$/);
    if (match) options[match[1]] = match[2];
    else positional.push(arg);
  }
  return { options, positional };
}

const commands = {
  where() {
    console.log(godotBinary());
    return true;
  },

  editor() {
    spawn(godotBinary({ gui: true }), ['--path', ROOT, '--editor'], { detached: true, stdio: 'ignore' }).unref();
    console.log('[dev] editor starting');
    return true;
  },

  async game(argv) {
    const scene = argv[0] ? [toResPath(argv[0])] : [];
    if (!(await ensureImported())) return false;
    return report('game', await godot(['--path', ROOT, ...scene]));
  },

  import: importAssets,

  async check() {
    if (!(await importAssets())) return false;
    const result = await godot(['--headless', '--path', ROOT, '--script', 'res://tools/check_project.gd'], {
      timeoutMs: 10 * 60_000,
    });
    return report('check', result);
  },

  async test(argv) {
    if (!(await ensureImported())) return false;
    const result = await godot(['--headless', '--path', ROOT, '--script', 'res://addons/gut/gut_cmdln.gd', ...argv], {
      timeoutMs: 15 * 60_000,
    });
    return report('test', result);
  },

  async shot(argv) {
    const { options, positional } = parseOptions(argv);
    const scene = positional[0] ? toResPath(positional[0]) : null;
    const name = scene ? path.basename(scene, path.extname(scene)) : 'main';
    const out = path.resolve(ROOT, options.out ?? path.join('.shots', `${name}.png`));
    mkdirSync(path.dirname(out), { recursive: true });
    if (existsSync(out)) rmSync(out);
    if (!(await ensureImported())) return false;
    const args = ['--path', ROOT, '--resolution', options.size ?? '1280x720'];
    if (scene) args.push(scene);
    args.push('--', `--shot=${out}`, `--shot-frames=${options.frames ?? 60}`);
    const ok = report('shot', await godot(args, { timeoutMs: 3 * 60_000 }));
    if (!existsSync(out) || statSync(out).size === 0) {
      console.log('[dev] no screenshot was written');
      return false;
    }
    console.log(`[dev] screenshot: ${out}`);
    return ok;
  },

  async api() {
    const out = path.join(ROOT, '.godot-api');
    mkdirSync(out, { recursive: true });
    // Run outside the project so only the engine's own classes are dumped.
    const result = await new Promise((resolve) => {
      const child = spawn(godotBinary(), ['--headless', '--doctool', out], { cwd: out, stdio: 'inherit' });
      child.on('close', (code) => resolve(code ?? 1));
      child.on('error', () => resolve(1));
    });
    if (result !== 0) return false;
    console.log(`[dev] Godot ${GODOT_VERSION} class reference: ${path.join(out, 'doc', 'classes')} (+ modules/*/doc_classes)`);
    return true;
  },
};

const [name, ...rest] = process.argv.slice(2);
const command = commands[name];
if (!command) {
  console.error(`usage: node tools/dev.mjs <${Object.keys(commands).join('|')}> [args]`);
  process.exit(2);
}
process.exit((await command(rest)) ? 0 : 1);
