// Visualiseur 3D du personnage, embarqué dans l'application (hors ligne).
// Construit avec esbuild en un seul script (assets/viewer/viewer.js) :
//   node build.mjs
// Interface appelée depuis Flutter via runJavaScript :
//   arise.beginModel(id) / arise.appendChunk(id, base64) / arise.endModel(id)
//   arise.apply(jsonApparence)
// Les messages vers Flutter passent par le canal JavaScript « AriseViewer ».
import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { MeshoptDecoder } from 'three/examples/jsm/libs/meshopt_decoder.module.js';
import { RoomEnvironment } from 'three/examples/jsm/environments/RoomEnvironment.js';
import * as SkeletonUtils from 'three/examples/jsm/utils/SkeletonUtils.js';

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
// Reflets doux d'une pièce virtuelle (générée, sans image ni réseau) :
// la peau, le cuir et les cheveux réagissent à la lumière ambiante.
const pmrem = new THREE.PMREMGenerator(renderer);
scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;
scene.environmentIntensity = 0.2;
const camera = new THREE.PerspectiveCamera(30, 1, 0.05, 50);
camera.position.set(0, 1.0, 4.2);
const controls = new OrbitControls(camera, renderer.domElement);
controls.target.set(0, 0.95, 0);
controls.enableDamping = true;
controls.enablePan = false;
controls.minDistance = 0.6;
controls.maxDistance = 8;
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
  let target = new THREE.Vector3(0, face ? h * 0.93 : h * 0.53, 0);
  let position = face
    ? new THREE.Vector3(0, h * 0.94, 1.0)
    : new THREE.Vector3(0, h * 0.56, h * 2.3);
  if (name === 'exercise_side') {
    // Profil (côté gauche du personnage), assez large pour les exercices au
    // sol (planche, pompes) : le personnage regarde vers la gauche.
    target = new THREE.Vector3(0, h * 0.46, 0);
    position = new THREE.Vector3(h * 3.1, h * 0.62, 0);
  } else if (name === 'army') {
    // Le personnage et son armée d'Ombres, un peu en hauteur.
    target = new THREE.Vector3(0, h * 0.48, -h * 0.55);
    position = new THREE.Vector3(0, h * 1.05, h * 3.2);
  } else if (name === 'exercise_front') {
    target = new THREE.Vector3(0, h * 0.5, 0);
    position = new THREE.Vector3(0, h * 0.58, h * 2.6);
  }
  focusAnim = {
    t: 0,
    fromT: controls.target.clone(),
    fromP: camera.position.clone(),
    toT: target,
    toP: position,
  };
}

// --- Aura : anneau lumineux au sol et particules qui montent -------------
function glowTexture() {
  const size = 128;
  const canvas = document.createElement('canvas');
  canvas.width = size;
  canvas.height = size;
  const ctx = canvas.getContext('2d');
  const g = ctx.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size / 2);
  g.addColorStop(0, 'rgba(255,255,255,1)');
  g.addColorStop(0.35, 'rgba(255,255,255,0.55)');
  g.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, size, size);
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  return texture;
}
const GLOW = glowTexture();
const AURA_PARTICLES = 70;
const aura = new THREE.Group();
aura.visible = false;
const auraFloor = new THREE.Mesh(
  new THREE.PlaneGeometry(1.6, 1.6),
  new THREE.MeshBasicMaterial({
    map: GLOW, transparent: true, opacity: 0.75, depthWrite: false,
    blending: THREE.AdditiveBlending,
  }),
);
auraFloor.rotation.x = -Math.PI / 2;
auraFloor.position.y = 0.01;
aura.add(auraFloor);
const auraRing = new THREE.Mesh(
  new THREE.RingGeometry(0.42, 0.47, 64),
  new THREE.MeshBasicMaterial({
    transparent: true, opacity: 0.8, depthWrite: false, side: THREE.DoubleSide,
    blending: THREE.AdditiveBlending,
  }),
);
auraRing.rotation.x = -Math.PI / 2;
auraRing.position.y = 0.02;
aura.add(auraRing);
const auraPositions = new Float32Array(AURA_PARTICLES * 3);
const auraSpeeds = new Float32Array(AURA_PARTICLES);
for (let i = 0; i < AURA_PARTICLES; i++) {
  const a = Math.random() * Math.PI * 2;
  const r = 0.25 + Math.random() * 0.3;
  auraPositions.set([Math.cos(a) * r, Math.random() * 1.9, Math.sin(a) * r], i * 3);
  auraSpeeds[i] = 0.15 + Math.random() * 0.35;
}
const auraGeometry = new THREE.BufferGeometry();
auraGeometry.setAttribute('position', new THREE.BufferAttribute(auraPositions, 3));
const auraPoints = new THREE.Points(
  auraGeometry,
  new THREE.PointsMaterial({
    map: GLOW, size: 0.06, transparent: true, opacity: 0.85, depthWrite: false,
    blending: THREE.AdditiveBlending,
  }),
);
aura.add(auraPoints);
const auraLight = new THREE.PointLight(0xffffff, 0, 2.2);
auraLight.position.set(0, 0.15, 0.6);
aura.add(auraLight);
scene.add(aura);

function setAura(color, height) {
  if (!color) {
    aura.visible = false;
    return;
  }
  const c = new THREE.Color(color);
  auraFloor.material.color.copy(c);
  auraRing.material.color.copy(c);
  auraPoints.material.color.copy(c);
  auraLight.color.copy(c);
  auraLight.intensity = 0.35;
  aura.scale.setScalar((height || 1.8) / 1.8);
  aura.visible = true;
}

function animateAura(delta, time) {
  if (!aura.visible) return;
  auraRing.rotation.z += delta * 0.4;
  auraRing.material.opacity = 0.6 + 0.25 * Math.sin(time * 2.2);
  const pos = auraGeometry.attributes.position;
  for (let i = 0; i < AURA_PARTICLES; i++) {
    let y = pos.getY(i) + auraSpeeds[i] * delta;
    if (y > 1.9) y = 0;
    pos.setY(i, y);
  }
  pos.needsUpdate = true;
}

// --- Ombres : silhouettes sombres et translucides du personnage ----------
const SHADOW_TINTS = ['#6d4cff', '#2fb5ff', '#ff4c7a', '#3ee6a8', '#ffb238', '#b04cff', '#4c7bff'];
// Places derrière le personnage (x, z), pour une taille de 1,8 m.
const SHADOW_SLOTS = [
  [-0.8, -0.9], [0.8, -0.9], [-1.5, -1.6], [1.5, -1.6], [0, -1.9], [-2.2, -2.3], [2.2, -2.3],
];
const army = { key: '', clones: [] };

function clearArmy() {
  for (const c of army.clones) {
    scene.remove(c.root);
    c.mixer.stopAllAction();
  }
  army.clones = [];
  army.key = '';
}

function setArmy(model, rig, indices, height) {
  const list = (indices || []).slice(0, SHADOW_SLOTS.length);
  const key = list.length ? model.uuid + ':' + list.join(',') + ':' + height.toFixed(3) : '';
  if (key === army.key) return;
  clearArmy();
  if (!list.length || !rig) return;
  army.key = key;
  const k = height / 1.8;
  list.forEach((index, slot) => {
    const root = SkeletonUtils.clone(model);
    const tint = new THREE.Color(SHADOW_TINTS[index % SHADOW_TINTS.length]);
    // Corps presque noir, teinte à peine lumineuse : une silhouette d'ombre.
    const material = new THREE.MeshStandardMaterial({
      color: tint.clone().multiplyScalar(0.03), emissive: tint, emissiveIntensity: 0.025,
      roughness: 1, metalness: 0, envMapIntensity: 0.2, transparent: true, opacity: 0.86,
    });
    root.traverse((o) => {
      if (o.isMesh) {
        o.material = material;
        o.frustumCulled = false;
      }
    });
    const [x, z] = SHADOW_SLOTS[slot];
    root.position.set(x * k, 0, z * k);
    const mixer = new THREE.AnimationMixer(root);
    const pose = rig.clips.pose_relaxed || rig.clips.pose_a;
    if (pose) mixer.clipAction(pose).play();
    scene.add(root);
    army.clones.push({ root, mixer });
  });
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
// Envois en cours, par modèle : deux envois ne se mélangent jamais.
const uploads = new Map();

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
    // Les volumes de découpe sont calculés au repos : pendant un exercice
    // (personnage déplacé, allongé), une pièce comme les cheveux sortirait
    // de son volume et disparaîtrait.
    o.frustumCulled = false;
    const mats = Array.isArray(o.material) ? o.material : [o.material];
    for (const m of mats) {
      if (!m) continue;
      if (m.name.startsWith('hair_') || m.name.startsWith('brow_') || m.name.startsWith('beard_') || m.name === 'lashes') {
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
      // Relief de la peau discret (pores), plus marqué sur les tissus.
      if (m.normalMap) m.normalScale.setScalar(m.name === 'skin' ? 0.35 : 0.8);
      m.needsUpdate = true;
    }
  });
}

// Pose selon l'arme portée : bâton, sceptre et hallebarde se tiennent
// avant-bras levé ; les autres armes, poing fermé le long du corps.
const STAFF_WEAPONS = ['item_staff_', 'item_scepter_', 'item_halberd_'];
const HAND_WEAPONS = ['item_sword_', 'item_dagger_', 'item_mace_', 'item_axe_', 'item_cleaver_', 'item_hammer_', 'item_scimitar_', 'item_glaive_'];
function restPose(items) {
  const list = items || [];
  if (list.some((i) => STAFF_WEAPONS.some((p) => i.startsWith(p)))) return 'pose_staff';
  if (list.some((i) => HAND_WEAPONS.some((p) => i.startsWith(p)))) return 'pose_hold';
  return 'pose_relaxed';
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
  const rig = { mixer, clips, pose: null, root: gltf.scene };
  const breath = additive('breath');
  if (breath) {
    const action = mixer.clipAction(breath);
    action.blendMode = THREE.AdditiveAnimationBlendMode;
    action.setLoop(THREE.LoopRepeat, Infinity).play();
    rig.breathAction = action;
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

// Tenues déjà rattachées (« <modèle>/<tenue> »).
const packs = new Set();

// Démonstration d'exercice : clip `ex_<mouvement>` en boucle, à la place de
// la pose détendue et de la respiration ; sinon pose détendue.
function setMotion(rig, motion, pose) {
  const clip = motion ? rig.clips['ex_' + motion] : null;
  const rest = pose || 'pose_relaxed';
  if (rig.motion === (clip ? clip.name : null) && rig.motionSet && (clip || rig.pose === rest)) return;
  rig.motionSet = true;
  rig.motion = clip ? clip.name : null;
  if (rig.exerciseAction) {
    rig.exerciseAction.stop();
    rig.exerciseAction = null;
  }
  if (clip) {
    if (rig.poseAction) rig.poseAction.stop();
    if (rig.breathAction) rig.breathAction.stop();
    rig.pose = null;
    rig.poseAction = null;
    // Le clip n'anime que les os qui bougent : les autres reviennent au repos.
    let skeleton = null;
    rig.root.traverse((o) => {
      if (!skeleton && o.isSkinnedMesh) skeleton = o.skeleton;
    });
    if (skeleton) skeleton.pose();
    const action = rig.mixer.clipAction(clip);
    action.reset().setLoop(THREE.LoopRepeat, Infinity).play();
    rig.exerciseAction = action;
  } else {
    if (rig.breathAction && !rig.breathAction.isRunning()) rig.breathAction.reset().play();
    setPose(rig, rest);
  }
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
    if (n.startsWith('outfit_under_')) {
      // Sous-vêtements : seulement quand un objet remplace la blouse ou le
      // pantalon de la tenue de départ.
      const covered = n.startsWith('outfit_under_top') ? 'outfit_tunic' : 'outfit_pants';
      o.visible = state.outfit !== false && (state.hiddenOutfit || []).includes(covered);
    } else if (n.startsWith('outfit_')) {
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
        (m.name.startsWith('beard_') ? colors.beard : null) ||
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
  if (rig) setMotion(rig, state.motion || null, restPose(state.items));
  setLighting(state.lighting);
  const height = model.userData.top * (state.scale || 1);
  const shadows = state.motion ? [] : state.shadows || [];
  setAura(state.motion ? null : state.aura, height);
  setArmy(model, rig, shadows, height);
  const focus = state.motion
    ? 'exercise_' + (state.view || 'side')
    : shadows.length && (state.focus || 'body') === 'body'
      ? 'army'
      : state.focus || 'body';
  if (focus !== currentFocus || model !== focusModel || state.scale !== focusScale) {
    currentFocus = focus;
    focusModel = model;
    focusScale = state.scale;
    // Hauteur du corps seul (les pièces masquées, bâton…, ne comptent pas),
    // à l'échelle choisie.
    setFocus(focus, model.userData.top * (state.scale || 1));
  }
  return true;
}

window.arise = {
  beginModel(id) {
    uploads.set(id, []);
  },
  appendChunk(id, b64) {
    const parts = uploads.get(id);
    if (parts) parts.push(decode(b64));
  },
  endModel(id) {
    const parts = uploads.get(id);
    uploads.delete(id);
    if (!parts) return;
    const size = parts.reduce((s, c) => s + c.length, 0);
    const all = new Uint8Array(size);
    let offset = 0;
    for (const c of parts) {
      all.set(c, offset);
      offset += c.length;
    }
    loader.parse(
      all.buffer,
      '',
      (gltf) => {
        prepareMaterials(gltf.scene);
        // Hauteur du corps au repos (avant toute animation) : le cadrage ne
        // suit pas les mouvements d'exercice.
        gltf.scene.updateMatrixWorld(true);
        const body = gltf.scene.getObjectByName('body') || gltf.scene;
        gltf.scene.userData.top = new THREE.Box3().setFromObject(body).max.y;
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
  // Tenue chargée à la demande (outfits/<tenue>/<modèle>.glb) : ses pièces
  // sont rattachées au squelette du modèle déjà chargé, os par os (même nom).
  endPack(key, modelId) {
    const parts = uploads.get(key);
    uploads.delete(key);
    const model = models.get(modelId);
    if (!parts || !model) return;
    const size = parts.reduce((s, c) => s + c.length, 0);
    const all = new Uint8Array(size);
    let offset = 0;
    for (const c of parts) {
      all.set(c, offset);
      offset += c.length;
    }
    loader.parse(
      all.buffer,
      '',
      (gltf) => {
        prepareMaterials(gltf.scene);
        const bones = {};
        let anchor = null;
        model.traverse((o) => {
          if (o.isBone) bones[o.name] = o;
          if (!anchor && o.isSkinnedMesh) anchor = o;
        });
        const pieces = [];
        gltf.scene.traverse((o) => {
          if (o.isSkinnedMesh) pieces.push(o);
        });
        for (const piece of pieces) {
          const skeleton = new THREE.Skeleton(
            piece.skeleton.bones.map((b) => bones[b.name] || b),
            piece.skeleton.boneInverses,
          );
          piece.removeFromParent();
          piece.visible = false;
          (anchor ? anchor.parent : model).add(piece);
          if (anchor) {
            piece.position.copy(anchor.position);
            piece.quaternion.copy(anchor.quaternion);
            piece.scale.copy(anchor.scale);
          }
          piece.bind(skeleton, anchor ? anchor.bindMatrix : piece.bindMatrix);
        }
        packs.add(key);
        post('loaded', { id: key });
      },
      (err) => post('error', { message: String(err) }),
    );
  },
  hasPack(key) {
    return packs.has(key);
  },
  apply(json) {
    const ok = applyState(JSON.parse(json));
    // « applied » part à l'image suivante, une fois le personnage dessiné
    // (la boucle de rendu passe avant ce rappel) : sur un appareil lent, le
    // premier rendu prend plusieurs secondes et l'écran de chargement doit
    // rester visible jusque-là.
    requestAnimationFrame(() => post('applied', { ok }));
  },
  capture() {
    renderer.render(scene, camera);
    post('capture', { data: renderer.domElement.toDataURL('image/png') });
  },
};

let lastSize = '';
function loop() {
  // La vue web peut changer de taille sans événement « resize » (ouverture
  // d'une fenêtre plein écran) : on vérifie à chaque image.
  const size = window.innerWidth + 'x' + window.innerHeight;
  if (size !== lastSize) {
    lastSize = size;
    resize();
  }
  const delta = clock.getDelta();
  for (const rig of rigs.values()) rig.mixer.update(delta);
  for (const c of army.clones) c.mixer.update(delta);
  animateAura(delta, clock.elapsedTime);
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
