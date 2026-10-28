#!/usr/bin/env node
// Dev commands for this Godot project, run through npm (see package.json):
//
//   npm run editor               open the project in the Godot editor
//   npm run game [-- <scene>] [--sector=C4]
//                                play the game, or one scene, in a window;
//                                --sector starts the player in that sector
//   npm run import               import new or changed assets, headless
//   npm run bake                 generate every sector design's content into
//                                baked/sectors/; game, shot and test do it
//                                first whenever the baked files are stale
//   npm run models               build the models made by Blender scripts in
//                                tools/blender/ (the hero) into assets/models/,
//                                then import them
//   npm run blender              open Blender (for the MCP tools)
//   npm run strings              collect every player-facing English string
//                                into locale/messages.pot
//   npm run check                import, then load every script, scene and
//                                resource in src/ data/ assets/ tests/ tools/
//   npm test [-- <gut args>]     run the GUT suite headless, e.g.
//                                npm test -- -gselect=test_fly_camera
//   npm run shot [-- <scene>] [--out=<png>] [--frames=<n>] [--size=<WxH>]
//                [--camera=x,y,z --look=x,y,z | --frame=A1:C3] [--sector=C4]
//                                play a scene in a window, save a PNG, quit;
//                                with --camera or --frame, shoot from there
//   npm run api                  dump the engine's class reference to .godot-api/
//   npm run where                print the Godot binary in use
//
// The engine is pinned to GODOT_VERSION below. Set the GODOT environment
// variable to use another binary (on Windows, the *_console.exe one).
// Blender is pinned to BLENDER_VERSION the same way, overridden by BLENDER.

import { spawn } from 'node:child_process';
import { existsSync, mkdirSync, readdirSync, rmSync, statSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const GODOT_VERSION = '4.7.2';
const BLENDER_VERSION = '5.2.3';
// Each builds one model; run in this order by `npm run models`.
const BLENDER_SCRIPTS = ['tools/blender/build_hero.py'];
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

function blenderBinary() {
  if (process.env.BLENDER) return process.env.BLENDER;
  if (process.platform === 'win32') {
    const exe = path.join(process.env.LOCALAPPDATA ?? '', 'Programs', 'Blender', BLENDER_VERSION, 'blender.exe');
    if (existsSync(exe)) return exe;
  }
  return 'blender';
}

// Runs a Blender script headless with factory settings, so add-ons and
// preferences on this machine can't change what it builds.
function blender(script) {
  return new Promise((resolve) => {
    const args = ['--background', '--factory-startup', '--python-exit-code', '1', '--python', path.join(ROOT, script)];
    const child = spawn(blenderBinary(), args, { cwd: ROOT, stdio: 'inherit' });
    child.on('close', (code) => resolve(code ?? 1));
    child.on('error', (error) => {
      console.error(`[dev] could not start Blender (${blenderBinary()}): ${error.message}`);
      resolve(1);
    });
  });
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

// Mirrors BakedSectors in src/world/streaming/baked_sectors.gd: baked
// content is stale once a source it comes from is newer than its stamp.
const BAKE_STAMP = path.join(ROOT, 'baked', 'sectors', 'stamp.txt');
const BAKE_SOURCES = ['src', 'data', path.join('tools', 'bake_sectors.gd')];
const BAKE_EXTENSIONS = new Set(['.gd', '.gdshader', '.tscn', '.tres', '.res']);

function newestSource(target) {
  if (!existsSync(target)) return 0;
  const stat = statSync(target);
  if (stat.isFile()) return BAKE_EXTENSIONS.has(path.extname(target)) ? stat.mtimeMs : 0;
  let newest = 0;
  for (const entry of readdirSync(target)) newest = Math.max(newest, newestSource(path.join(target, entry)));
  return newest;
}

function isBakeFresh() {
  if (!existsSync(BAKE_STAMP)) return false;
  // Godot compares whole seconds, so this does too.
  const stamp = Math.floor(statSync(BAKE_STAMP).mtimeMs / 1000);
  return BAKE_SOURCES.every((source) => Math.floor(newestSource(path.join(ROOT, source)) / 1000) <= stamp);
}

async function bake() {
  if (!(await ensureImported())) return false;
  // A script error leaves Godot running, so the timeout is what stops it.
  const result = await godot(['--headless', '--path', ROOT, '--script', 'res://tools/bake_sectors.gd'], {
    timeoutMs: 10 * 60_000,
  });
  return report('bake', result);
}

async function ensureBaked() {
  return isBakeFresh() || bake();
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
    const { options, positional } = parseOptions(argv);
    const scene = positional[0] ? [toResPath(positional[0])] : [];
    const user = options.sector ? ['--', `--sector=${options.sector}`] : [];
    if (!(await ensureImported()) || !(await ensureBaked())) return false;
    return report('game', await godot(['--path', ROOT, ...scene, ...user]));
  },

  import: importAssets,

  bake,

  async models() {
    for (const script of BLENDER_SCRIPTS) {
      const code = await blender(script);
      console.log(`\n[dev] blender ${script}: exit ${code}`);
      if (code !== 0) return false;
    }
    return importAssets();
  },

  // Opens Blender with the MCP for Blender add-on's telemetry and its
  // update check off, so it stays the pinned version and sends nothing.
  blender() {
    const env = { ...process.env, DISABLE_TELEMETRY: 'true', BLENDERMCP_NO_UPDATE_CHECK: '1' };
    spawn(blenderBinary(), [], { detached: true, stdio: 'ignore', env }).unref();
    console.log('[dev] Blender starting');
    return true;
  },

  async strings() {
    if (!(await ensureImported())) return false;
    const result = await godot(['--headless', '--path', ROOT, '--script', 'res://tools/extract_strings.gd'], {
      timeoutMs: 3 * 60_000,
    });
    return report('strings', result);
  },

  async check() {
    if (!(await importAssets())) return false;
    const result = await godot(['--headless', '--path', ROOT, '--script', 'res://tools/check_project.gd'], {
      timeoutMs: 10 * 60_000,
    });
    return report('check', result);
  },

  async test(argv) {
    if (!(await ensureImported()) || !(await ensureBaked())) return false;
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
    if (!(await ensureImported()) || !(await ensureBaked())) return false;
    const args = ['--path', ROOT, '--resolution', options.size ?? '1280x720'];
    if (scene) args.push(scene);
    args.push('--', `--shot=${out}`, `--shot-frames=${options.frames ?? 60}`);
    if (options.camera) args.push(`--shot-camera=${options.camera}`, `--shot-look=${options.look ?? '0,0,0'}`);
    if (options.frame) args.push(`--shot-frame=${options.frame}`);
    if (options.sector) args.push(`--sector=${options.sector}`);
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
