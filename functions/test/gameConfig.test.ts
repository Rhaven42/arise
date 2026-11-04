import { gameConfig } from '../src/config/gameConfig';

/** Lit une valeur de la configuration à partir d'un chemin « a.b ». */
function valueAt(path: string): unknown {
  return path.split('.').reduce<unknown>((node, key) => {
    if (node !== null && typeof node === 'object' && key in node) {
      return (node as Record<string, unknown>)[key];
    }
    return undefined;
  }, gameConfig);
}

function isStrictlyIncreasing(values: readonly number[]): boolean {
  return values.every((value, index) => index === 0 || value > (values[index - 1] ?? value));
}

describe('cohérence de la configuration de jeu', () => {
  it('les rangs sont ordonnés et commencent au niveau 1', () => {
    const levels = gameConfig.ranks.map((rank) => rank.minLevel);
    expect(levels[0]).toBe(1);
    expect(isStrictlyIncreasing(levels)).toBe(true);
  });

  it('le dernier rang est atteignable avant le niveau maximum', () => {
    const last = gameConfig.ranks[gameConfig.ranks.length - 1];
    expect(last?.minLevel).toBeLessThan(gameConfig.progression.maxLevel);
  });

  it('les seuils de la heatmap sont strictement croissants', () => {
    expect(isStrictlyIncreasing(gameConfig.heatmap.weeklyThresholds)).toBe(true);
    expect(isStrictlyIncreasing(gameConfig.heatmap.dailyThresholds)).toBe(true);
  });

  it('les paliers de coffres sont strictement croissants', () => {
    expect(isStrictlyIncreasing(gameConfig.streaks.chestMilestonesDays)).toBe(true);
  });

  it('le bonus de série plafonne après un nombre entier de jours', () => {
    const days = gameConfig.streaks.maxBonus / gameConfig.streaks.bonusPerDay;
    expect(Math.round(days)).toBeCloseTo(days, 10);
  });

  it('les bornes d’intensité sont cohérentes', () => {
    const { rpeMin, rpeMax, multiplierMin, multiplierMax, effectiveSetMinRpe } =
      gameConfig.intensity;
    expect(rpeMin).toBeLessThan(rpeMax);
    expect(multiplierMin).toBeLessThan(multiplierMax);
    expect(effectiveSetMinRpe).toBeGreaterThanOrEqual(rpeMin);
    expect(effectiveSetMinRpe).toBeLessThanOrEqual(rpeMax);
  });

  it('chaque clé provisoire désigne une valeur existante', () => {
    for (const key of gameConfig.provisionalKeys) {
      expect(valueAt(key)).toBeDefined();
    }
  });
});
