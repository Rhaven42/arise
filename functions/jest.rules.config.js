// Tests des règles de sécurité : à lancer via « firebase emulators:exec ».
/** @type {import('jest').Config} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/test/rules'],
};
