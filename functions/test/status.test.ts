import { gameConfig } from '../src/config/gameConfig';
import { buildSystemStatus } from '../src/system/status';

describe('buildSystemStatus', () => {
  it('renvoie un état valide avec la version de la configuration', () => {
    expect(buildSystemStatus()).toStrictEqual({
      status: 'ok',
      gameConfigVersion: gameConfig.version,
    });
  });
});
