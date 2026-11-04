import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import { gameConfig } from '../src/config/gameConfig';

// Le même instantané est vérifié par le test Dart : si les deux tests
// passent, les configurations client et serveur sont identiques.
const snapshotPath = join(__dirname, '..', '..', 'shared', 'game_config.snapshot.json');

describe('parité de la configuration de jeu', () => {
  it('correspond exactement à l’instantané partagé', () => {
    const snapshot: unknown = JSON.parse(readFileSync(snapshotPath, 'utf8'));
    expect(JSON.parse(JSON.stringify(gameConfig))).toStrictEqual(snapshot);
  });
});
