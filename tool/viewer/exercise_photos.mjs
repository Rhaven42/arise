// Importe les photos de démonstration des exercices depuis free-exercise-db
// (domaine public) : deux poses par exercice (départ, arrivée), réduites et
// converties en WebP dans assets/exercise_photos/<exercice>_<0|1>.webp.
//
// Usage (depuis la racine du dépôt) :
//   git clone --depth 1 https://github.com/yuhonas/free-exercise-db <dossier>
//   node tool/viewer/exercise_photos.mjs <dossier>
import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';

const source = process.argv[2];
const mapping = JSON.parse(fs.readFileSync('tool/exercise_photos/mapping.json', 'utf8'));
const out = 'assets/exercise_photos';
fs.mkdirSync(out, { recursive: true });
for (const file of fs.readdirSync(out)) fs.rmSync(path.join(out, file));
let total = 0;
for (const [id, name] of Object.entries(mapping.photos)) {
  for (const frame of [0, 1]) {
    const input = path.join(source, 'exercises', name, `${frame}.jpg`);
    const target = path.join(out, `${id}_${frame}.webp`);
    await sharp(input).resize({ width: 640, withoutEnlargement: true }).webp({ quality: 70 }).toFile(target);
    total += fs.statSync(target).size;
  }
}
console.log(`${Object.keys(mapping.photos).length} exercices, ${(total / 1048576).toFixed(1)} Mo`);
