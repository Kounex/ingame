import { execSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

import { describe, expect, it } from 'vitest';

const projectRoot = process.cwd();
const distIndexPath = path.join(projectRoot, 'dist', 'index.html');

function readBuiltCss(html: string): string {
  const stylesheetMatch = html.match(/<link rel="stylesheet" href="([^"]+)">/);
  if (stylesheetMatch?.[1] != null) {
    const cssPath = path.join(projectRoot, 'dist', stylesheetMatch[1].replace(/^\//, ''));
    return fs.readFileSync(cssPath, 'utf8');
  }

  const inlineCssMatch = html.match(/<style>([\s\S]*?)<\/style>/);
  return inlineCssMatch?.[1] ?? '';
}

describe('marketing build styling', () => {
  it('emits the utility CSS needed by the homepage layout', () => {
    execSync('npm run build', {
      cwd: projectRoot,
      stdio: 'pipe',
    });

    const html = fs.readFileSync(distIndexPath, 'utf8');
    const css = readBuiltCss(html);

    expect(html).toContain('px-6');
    expect(html).toContain('max-w-6xl');
    expect(html).toContain('bg-ig-primary');
    expect(html).toContain('shadow-glow');

    expect(css).toContain('.px-6');
    expect(css).toContain('.max-w-6xl');
    expect(css).toContain('.rounded-xl');
    expect(css).toContain('.bg-ig-primary');
    expect(css).toContain('.shadow-glow');
    expect(css).toContain('.text-white\\/70');
  });
});
