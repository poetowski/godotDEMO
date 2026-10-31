// A Claude Code hook (UserPromptSubmit, in .claude/settings.json): says so when the
// land or water has changes not yet committed, so Claude can offer /land-sync. Stays
// silent otherwise, and on any error, so it never gets in the way of a prompt.
import { execFileSync } from 'node:child_process';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');

try {
  const status = execFileSync('git', ['-C', ROOT, 'status', '--porcelain', '--', 'data/world/sculpt', 'data/world/water'], {
    encoding: 'utf8',
    timeout: 8000,
  });
  const changed = status.split('\n').filter(Boolean).length;
  if (changed > 0) {
    console.log(`The author has ${changed} uncommitted land or water file(s) in data/world/. Unless this prompt is about something else entirely, follow /land-sync: run npm run land-check with the editor closed and propose what the changes call for.`);
  }
} catch {
  // Not worth interrupting a prompt for.
}
