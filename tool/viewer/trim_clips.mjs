// Allège les clips d'exercice (`ex_*`) d'un modèle glb : l'exporteur de
// Blender échantillonne tous les os, y compris ceux qui ne bougent pas.
// Les pistes qui restent à la position de repos de l'os sont supprimées ;
// le visualiseur remet le squelette au repos avant de jouer un clip.
//
// Usage : node trim_clips.mjs <entrée.glb> <sortie.glb>
import { NodeIO } from '@gltf-transform/core';
import { ALL_EXTENSIONS } from '@gltf-transform/extensions';
import { prune } from '@gltf-transform/functions';

const [input, output] = process.argv.slice(2);
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS);
const doc = await io.read(input);
const EPS = 1e-4;

function rest(node, path) {
  if (path === 'translation') return node.getTranslation();
  if (path === 'rotation') return node.getRotation();
  if (path === 'scale') return node.getScale();
  return null;
}

let removed = 0;
for (const animation of doc.getRoot().listAnimations()) {
  if (!animation.getName().startsWith('ex_')) continue;
  for (const channel of animation.listChannels()) {
    const node = channel.getTargetNode();
    const base = node && rest(node, channel.getTargetPath());
    if (!base) continue;
    const values = channel.getSampler().getOutput().getArray();
    const size = base.length;
    let still = true;
    for (let i = 0; i < values.length && still; i += size) {
      // q et -q désignent la même rotation.
      let same = true;
      let opposite = true;
      for (let k = 0; k < size; k++) {
        if (Math.abs(values[i + k] - base[k]) > EPS) same = false;
        if (Math.abs(values[i + k] + base[k]) > EPS) opposite = false;
      }
      still = same || (size === 4 && opposite);
    }
    if (still) {
      const sampler = channel.getSampler();
      channel.dispose();
      sampler.dispose();
      removed++;
    }
  }
}
await doc.transform(prune());
await io.write(output, doc);
console.log(`${removed} pistes immobiles supprimées`);
