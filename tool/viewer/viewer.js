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
import { MeshoptDecoder } from 'three/examples/jsm/libs/meshopt_decoder.module.js';

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
controls.minDistance = 0.6;
controls.maxDistance = 5.5;
controls.minPolarAngle = 0.35;
controls.maxPolarAngle = 1.75;

// Éclairages : jour, nuit, taverne (lumière principale, contre-jour, ambiance).
const hemi = new THREE.HemisphereLight(0xffe2c0, 0x2a1a12, 0.9);
scene.add(hemi);
const key = new THREE.DirectionalLight(0xffd6a8, 2.4);
key.position.set(2, 3, 3);
scene.add(key);
const rim = new THREE.DirectionalLight(0xffb070, 1.6);
rim.position.set(-1.5, 2.5, -3);
scene.add(rim);
const LIGHTINGS = {
  day: { hemi: [0xfff4e6, 0x6b5a48, 1.2], key: [0xfff1dc, 2.6], rim: [0xcfe3ff, 1.0] },
  night: { hemi: [0x7f9cd6, 0x10121c, 0.55], key: [0xa9c0ff, 1.3], rim: [0x6f8cff, 1.4] },
  tavern: { hemi: [0xffe2c0, 0x2a1a12, 0.9], key: [0xffd6a8, 2.4], rim: [0xffb070, 1.6] },
};
function setLighting(name) {
  const l = LIGHTINGS[name] || LIGHTINGS.tavern;
  hemi.color.setHex(l.hemi[0]);
  hemi.groundColor.setHex(l.hemi[1]);
  hemi.intensity = l.hemi[2];
  key.color.setHex(l.key[0]);
  key.intensity = l.key[1];
  rim.color.setHex(l.rim[0]);
  rim.intensity = l.rim[1];
}

// Cadrage : corps entier ou visage, d'après la hauteur réelle du modèle.
let focusAnim = null;
function setFocus(name, top) {
  const h = top > 0.5 ? top : 1.8;
  const face = name === 'face';
  const target = new THREE.Vector3(0, face ? h * 0.93 : h * 0.53, 0);
  const position = face
    ? new THREE.Vector3(0, h * 0.94, 1.0)
    : new THREE.Vector3(0, h * 0.56, h * 2.3);
  focusAnim = {
    t: 0,
    fromT: controls.target.clone(),
    fromP: camera.position.clone(),
    toT: target,
    toP: position,
  };
}

const loader = new GLTFLoader();
// Modèles compressés (EXT_meshopt_compression) : décodeur embarqué, hors ligne.
loader.setMeshoptDecoder(MeshoptDecoder);
const models = new Map();
const rigs = new Map();
const clock = new THREE.Clock();
let currentFocus = 'body';
let focusModel = null;
let focusScale = null;
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

// Cheveux, sourcils et cils : textures à découpe (alphaTest), deux faces.
// Maquillages : couleurs de sommets avec transparence, posés sur la peau.
function prepareMaterials(root) {
  root.traverse((o) => {
    if (!o.isMesh) return;
    const mats = Array.isArray(o.material) ? o.material : [o.material];
    for (const m of mats) {
      if (!m) continue;
      if (m.name.startsWith('hair_') || m.name.startsWith('brow_') || m.name === 'lashes') {
        m.transparent = false;
        m.alphaTest = 0.4;
        m.side = THREE.DoubleSide;
        m.depthWrite = true;
      }
      if (m.name.startsWith('makeup_')) {
        m.vertexColors = true;
        m.transparent = true;
        m.depthWrite = false;
        m.polygonOffset = true;
        m.polygonOffsetFactor = -2;
        m.polygonOffsetUnits = -2;
        m.roughness = 0.6;
        o.renderOrder = 2;
      }
      m.needsUpdate = true;
    }
  });
}

// Pose détendue fixe et respiration (clip additif).
function buildRig(gltf) {
  const mixer = new THREE.AnimationMixer(gltf.scene);
  const clips = {};
  for (const clip of gltf.animations) clips[clip.name] = clip;
  const rest = clips.pose_a;
  const additive = (name) => {
    const clip = clips[name];
    if (!clip || !rest) return null;
    const copy = clip.clone();
    THREE.AnimationUtils.makeClipAdditive(copy, 0, rest);
    return copy;
  };
  const rig = { mixer, clips, pose: null };
  const breath = additive('breath');
  if (breath) {
    const action = mixer.clipAction(breath);
    action.blendMode = THREE.AdditiveAnimationBlendMode;
    action.setLoop(THREE.LoopRepeat, Infinity).play();
  }
  return rig;
}

function setPose(rig, poseName) {
  const clip = rig.clips[poseName] || rig.clips.pose_a;
  if (clip && rig.pose !== clip.name) {
    // reset() réactive une pose déjà quittée (désactivée en fin de fondu).
    const next = rig.mixer.clipAction(clip);
    next.reset().setLoop(THREE.LoopRepeat, Infinity).play();
    if (rig.poseAction) rig.poseAction.crossFadeTo(next, 0.35, false);
    rig.poseAction = next;
    rig.pose = clip.name;
  }
}

const LASHES = new THREE.Color('#1c1410');

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
  const colors = {
    skin: new THREE.Color(state.skinColor),
    hair: new THREE.Color(state.hairColor),
    brow: new THREE.Color(state.hairColor),
    beard: new THREE.Color(state.beardColor || state.hairColor),
    iris: new THREE.Color(state.eyeColor || '#4a2a14'),
  };
  const choice = { hair_: state.hairNode, brow_: state.browNode, beard_: state.beardNode, makeup_: state.makeupNode };
  model.traverse((o) => {
    if (!o.isMesh) return;
    const n = o.name || '';
    for (const [prefix, chosen] of Object.entries(choice)) {
      if (n.startsWith(prefix)) o.visible = n === chosen;
    }
    if (n.startsWith('outfit_')) {
      o.visible = state.outfit !== false && !(state.hiddenOutfit || []).includes(n);
    }
    if (n.startsWith('item_')) {
      // Une pièce à plusieurs matériaux devient « item_x_1 », « item_x_2 »…
      o.visible = (state.items || []).some((i) => n === i || n.startsWith(i + '_'));
    }
    const mats = Array.isArray(o.material) ? o.material : [o.material];
    for (const m of mats) {
      if (!m) continue;
      const tint = colors[m.name] ||
        (m.name.startsWith('hair_') || m.name.startsWith('brow_') ? colors.hair : null) ||
        (m.name === 'lashes' ? LASHES : null);
      if (tint) m.color.copy(tint);
      if (m.name.startsWith('dye_')) {
        // Couleur d'origine gardée pour revenir sans teinture.
        if (!m.userData.base) m.userData.base = m.color.clone();
        const dye = (state.dyes || {})[m.name];
        m.color.copy(dye ? new THREE.Color(dye) : m.userData.base);
      }
    }
  });
  const rig = rigs.get(state.model);
  if (rig) setPose(rig, 'pose_relaxed');
  setLighting(state.lighting);
  const focus = state.focus || 'body';
  if (focus !== currentFocus || model !== focusModel || state.scale !== focusScale) {
    currentFocus = focus;
    focusModel = model;
    focusScale = state.scale;
    model.updateMatrixWorld(true);
    // Hauteur du corps seul : les pièces masquées (bâton…) ne comptent pas.
    const body = model.getObjectByName('body') || model;
    setFocus(focus, new THREE.Box3().setFromObject(body).max.y);
  }
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
        prepareMaterials(gltf.scene);
        models.set(id, gltf.scene);
        rigs.set(id, buildRig(gltf));
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
    post('capture', { data: renderer.domElement.toDataURL('image/png') });
  },
};

function loop() {
  const delta = clock.getDelta();
  for (const rig of rigs.values()) rig.mixer.update(delta);
  if (focusAnim) {
    focusAnim.t = Math.min(1, focusAnim.t + delta / 0.5);
    const k = focusAnim.t * focusAnim.t * (3 - 2 * focusAnim.t);
    controls.target.lerpVectors(focusAnim.fromT, focusAnim.toT, k);
    camera.position.lerpVectors(focusAnim.fromP, focusAnim.toP, k);
    if (focusAnim.t >= 1) focusAnim = null;
  }
  controls.update();
  renderer.render(scene, camera);
  requestAnimationFrame(loop);
}
loop();
post('ready', {});
