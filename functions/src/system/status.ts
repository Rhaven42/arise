import { gameConfig } from '../config/gameConfig';

/** État renvoyé au client pour vérifier la connexion au serveur. */
export interface SystemStatus {
  readonly status: 'ok';
  readonly gameConfigVersion: number;
}

/** Construit l'état du serveur à partir de la configuration de jeu. */
export function buildSystemStatus(): SystemStatus {
  return { status: 'ok', gameConfigVersion: gameConfig.version };
}
