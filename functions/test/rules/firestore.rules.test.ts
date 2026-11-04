import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';

// Ces tests nécessitent l'émulateur Firestore :
// firebase emulators:exec --only firestore "npm --prefix functions run test:rules"
let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-arise',
    firestore: {
      rules: readFileSync(join(__dirname, '..', '..', '..', 'firestore.rules'), 'utf8'),
    },
  });
});

afterAll(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/alice'), { displayName: 'Alice' });
    await setDoc(doc(db, 'users/alice/progression/current'), { level: 0 });
    await setDoc(doc(db, 'catalog_exercises/push_up'), { name: 'Pompes' });
  });
});

describe('données utilisateur', () => {
  it('un visiteur non connecté ne lit rien', async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'users/alice')));
  });

  it('un utilisateur lit son profil et sa progression', async () => {
    const db = env.authenticatedContext('alice').firestore();
    await assertSucceeds(getDoc(doc(db, 'users/alice')));
    await assertSucceeds(getDoc(doc(db, 'users/alice/progression/current')));
  });

  it('un utilisateur ne lit pas les données d’un autre', async () => {
    const db = env.authenticatedContext('bob').firestore();
    await assertFails(getDoc(doc(db, 'users/alice')));
    await assertFails(getDoc(doc(db, 'users/alice/progression/current')));
  });

  it('le client ne peut pas écrire sa progression', async () => {
    const db = env.authenticatedContext('alice').firestore();
    await assertFails(setDoc(doc(db, 'users/alice/progression/current'), { level: 99 }));
  });
});

describe('catalogues', () => {
  it('sont lisibles par un utilisateur connecté', async () => {
    const db = env.authenticatedContext('alice').firestore();
    await assertSucceeds(getDoc(doc(db, 'catalog_exercises/push_up')));
  });

  it('sont fermés aux visiteurs et en écriture', async () => {
    await assertFails(
      getDoc(doc(env.unauthenticatedContext().firestore(), 'catalog_exercises/push_up')),
    );
    await assertFails(
      setDoc(doc(env.authenticatedContext('alice').firestore(), 'catalog_exercises/hack'), {
        name: 'Triche',
      }),
    );
  });
});

describe('réservations de noms et collections inconnues', () => {
  it('sont refusées au client', async () => {
    const db = env.authenticatedContext('alice').firestore();
    await assertFails(setDoc(doc(db, 'usernames/alice'), { uid: 'alice' }));
    await assertFails(getDoc(doc(db, 'anything/else')));
  });
});
