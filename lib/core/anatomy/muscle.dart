import 'package:json_annotation/json_annotation.dart';

/// Vue de la silhouette sur laquelle un muscle est dessiné.
enum BodyView { front, back }

/// Rôle d'un muscle dans un exercice.
enum MuscleRole { primary, secondary }

/// Muscles du référentiel anatomique (docs/ANATOMY.md §1).
///
/// [key] est l'identifiant stable utilisé dans les catalogues, les
/// sauvegardes et les silhouettes SVG.
@JsonEnum(valueField: 'key')
enum MuscleId {
  sternocleidomastoid('sternocleidomastoid', BodyView.front),
  pectoralisUpper('pectoralis_upper', BodyView.front),
  pectoralisMidLower('pectoralis_mid_lower', BodyView.front),
  deltoidAnterior('deltoid_anterior', BodyView.front),
  deltoidLateral('deltoid_lateral', BodyView.front),
  bicepsBrachii('biceps_brachii', BodyView.front),
  brachialis('brachialis', BodyView.front),
  forearmFlexors('forearm_flexors', BodyView.front),
  brachioradialis('brachioradialis', BodyView.front),
  rectusAbdominis('rectus_abdominis', BodyView.front),
  obliques('obliques', BodyView.front),
  transversusAbdominis('transversus_abdominis', BodyView.front),
  serratusAnterior('serratus_anterior', BodyView.front),
  hipFlexors('hip_flexors', BodyView.front),
  adductors('adductors', BodyView.front),
  abductors('abductors', BodyView.front),
  quadriceps('quadriceps', BodyView.front),
  tibialisAnterior('tibialis_anterior', BodyView.front),
  trapeziusUpper('trapezius_upper', BodyView.back),
  trapeziusMidLower('trapezius_mid_lower', BodyView.back),
  rhomboids('rhomboids', BodyView.back),
  latissimusDorsi('latissimus_dorsi', BodyView.back),
  teresMajor('teres_major', BodyView.back),
  deltoidPosterior('deltoid_posterior', BodyView.back),
  rotatorCuff('rotator_cuff', BodyView.back),
  tricepsBrachii('triceps_brachii', BodyView.back),
  forearmExtensors('forearm_extensors', BodyView.back),
  erectorSpinae('erector_spinae', BodyView.back),
  gluteusMaximus('gluteus_maximus', BodyView.back),
  gluteusMedius('gluteus_medius', BodyView.back),
  hamstrings('hamstrings', BodyView.back),
  gastrocnemius('gastrocnemius', BodyView.back),
  soleus('soleus', BodyView.back);

  MuscleId(this.key, this.view);

  final String key;
  final BodyView view;

  static final Map<String, MuscleId> _byKey = {
    for (final muscle in values) muscle.key: muscle,
  };

  /// Muscle correspondant à [key], ou `null` s'il n'existe pas.
  static MuscleId? tryParse(String key) => _byKey[key];
}
