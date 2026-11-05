// Visualiseur 3D du personnage, embarqué dans l'application (hors ligne).
// Construit avec esbuild en un seul script (assets/viewer/viewer.js) :
//   node build.mjs
// Interface appelée depuis Flutter via runJavaScript :
//   arise.beginModel(id) / arise.appendChunk(base64) / arise.endModel()
//   arise.apply(jsonApparence)
// Les messages vers Flutter passent par le canal JavaScript « AriseViewer ».
import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

const post = (type, data) => {
  const msg = JSON.stringify({ type, ...data });
  if (window.AriseViewer) window.AriseViewer.postMessage(msg);
};

const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, preserveDrawingBuffer: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.0;
document.body.appendChild(renderer.domElement);

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(30, 1, 0.05, 50);
camera.position.set(0, 1.0, 4.2);
const controls = new OrbitControls(camera, renderer.domElement);
controls.target.set(0, 0.95, 0);
controls.enableDamping = true;
controls.enablePan = false;
controls.minDistance = 0.9;
controls.maxDistance = 5.5;
controls.minPolarAngle = 0.35;
controls.maxPolarAngle = 1.75;

// Éclairage chaud de taverne : lumière principale, contre-jour, ambiance.
scene.add(new THREE.HemisphereLight(0xffe2c0, 0x2a1a12, 0.9));
const key = new THREE.DirectionalLight(0xffd6a8, 2.4);
key.position.set(2, 3, 3);
scene.add(key);
const rim = new THREE.DirectionalLight(0xffb070, 1.6);
rim.position.set(-1.5, 2.5, -3);
scene.add(rim);

const loader = new GLTFLoader();
const models = new Map();
let current = null;
let pending = null;
let buffer = null;

function resize() {
  const w = window.innerWidth;
  const h = window.innerHeight;
  renderer.setSize(w, h, false);
  renderer.domElement.style.width = w + 'px';
  renderer.domElement.style.height = h + 'px';
  camera.aspect = w / Math.max(h, 1);
  camera.updateProjectionMatrix();
}
window.addEventListener('resize', resize);
resize();

function decode(b64) {
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

function setMorph(root, name, value) {
  root.traverse((o) => {
    if (o.isMesh && o.morphTargetDictionary && name in o.morphTargetDictionary) {
      o.morphTargetInfluences[o.morphTargetDictionary[name]] = value;
    }
  });
}

function applyState(state) {
  const model = models.get(state.model);
  if (!model) return false;
  if (current !== model) {
    if (current) scene.remove(current);
    scene.add(model);
    current = model;
  }
  for (const [name, value] of Object.entries(state.morphs || {})) setMorph(model, name, value);
  model.scale.setScalar(state.scale || 1);
  const skin = new THREE.Color(state.skinColor);
  const hair = new THREE.Color(state.hairColor);
  model.traverse((o) => {
    if (!o.isMesh) return;
    const n = o.name || '';
    if (n.startsWith('hair_')) o.visible = n === state.hairNode;
    if (n.startsWith('outfit_')) o.visible = state.outfit !== false;
    const mats = Array.isArray(o.material) ? o.material : [o.material];
    for (const m of mats) {
      if (!m) continue;
      if (m.name === 'skin') m.color.copy(skin);
      if (m.name === 'hair') m.color.copy(hair);
    }
  });
  return true;
}

window.arise = {
  beginModel(id) {
    pending = id;
    buffer = [];
  },
  appendChunk(b64) {
    buffer.push(decode(b64));
  },
  endModel() {
    const size = buffer.reduce((s, c) => s + c.length, 0);
    const all = new Uint8Array(size);
    let offset = 0;
    for (const c of buffer) {
      all.set(c, offset);
      offset += c.length;
    }
    const id = pending;
    buffer = null;
    loader.parse(
      all.buffer,
      '',
      (gltf) => {
        models.set(id, gltf.scene);
        post('loaded', { id });
      },
      (err) => post('error', { message: String(err) }),
    );
  },
  hasModel(id) {
    return models.has(id);
  },
  apply(json) {
    const ok = applyState(JSON.parse(json));
    post('applied', { ok });
  },
  capture() {
    renderer.render(scene, camera);
    return renderer.domElement.toDataURL('image/png');
  },
};

function loop() {
  controls.update();
  renderer.render(scene, camera);
  requestAnimationFrame(loop);
}
loop();
post('ready', {});
