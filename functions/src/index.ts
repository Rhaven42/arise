/**
 * Point d'entrée des Cloud Functions d'ARISE.
 * Région européenne par défaut : les données des utilisateurs restent en UE.
 */
import { setGlobalOptions } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { buildSystemStatus } from './system/status';

setGlobalOptions({ region: 'europe-west1', maxInstances: 10 });

/** Permet au client de vérifier que le serveur répond. */
export const systemStatus = onCall(() => buildSystemStatus());
