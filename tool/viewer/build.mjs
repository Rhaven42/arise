// Construit assets/viewer/viewer.js (un seul script, sans module ni réseau).
import { build } from 'esbuild';

await build({
  entryPoints: ['tool/viewer/viewer.js'],
  bundle: true,
  minify: true,
  format: 'iife',
  target: ['es2019'],
  legalComments: 'eof',
  outfile: 'assets/viewer/viewer.js',
});
