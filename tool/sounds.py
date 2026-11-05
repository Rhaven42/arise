"""Génère les sons originaux du lecteur de séance (assets/sounds/*.wav).

Sons de synthèse (ondes sinusoïdales avec enveloppe), sans aucune source
externe. Usage : python3 tool/sounds.py
"""
import math
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"


def tone(freqs, duration, volume=0.45, attack=0.005, release=0.06):
    """Échantillons d'un accord (liste de fréquences) avec enveloppe douce."""
    total = int(RATE * duration)
    samples = []
    for i in range(total):
        t = i / RATE
        env = min(1.0, t / attack) * min(1.0, (duration - t) / release)
        value = sum(math.sin(2 * math.pi * f * t) for f in freqs) / len(freqs)
        samples.append(volume * max(0.0, env) * value)
    return samples


def silence(duration):
    return [0.0] * int(RATE * duration)


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(
            b"".join(struct.pack("<h", int(s * 32767)) for s in samples)
        )


# Décompte des 3 dernières secondes : bip court et sec.
write("countdown.wav", tone([880], 0.09))
# Début d'un effort : deux notes montantes, comme un cor léger.
write("start.wav", tone([660], 0.12) + silence(0.03) + tone([990], 0.22))
# Début d'un repos : note descendante, plus douce.
write("rest.wav", tone([740, 555], 0.3, volume=0.35))
# Fin de séance : accord majeur arpégé.
write(
    "finish.wav",
    tone([523], 0.14) + tone([659], 0.14) + tone([784], 0.14)
    + tone([523, 659, 784, 1047], 0.5, volume=0.4),
)
print("Sons générés dans", OUT)
