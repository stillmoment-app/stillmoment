/* gong-audio.jsx — WebAudio gong synthesis + voice-bed waveform model.
   The whole point: the gong's default level is DERIVED from the recording's
   loudness (its waveform), so it always sits a touch above the spoken voice. */

(function () {
  let ctx = null;
  function ac() {
    if (!ctx) ctx = new (window.AudioContext || window.webkitAudioContext)();
    if (ctx.state === "suspended") ctx.resume();
    return ctx;
  }

  /* ---- Tone recipes: inharmonic partials + decay shape per gong ---- */
  const TONES = {
    "Tempelglocke": {
      desc: "Tiefe, lang ausklingende Bronze",
      partials: [[1, 1], [2.76, 0.5], [5.4, 0.28], [8.9, 0.14]],
      base: 174, decay: 3.4, strike: 0.55, hue: "#A2503E",
    },
    "Klangschale": {
      desc: "Tibetische Schale, weich obertonig",
      partials: [[1, 1], [2.7, 0.6], [4.1, 0.4], [6.8, 0.25], [10.2, 0.12]],
      base: 238, decay: 4.2, strike: 0.3, hue: "#9A6A3C",
    },
    "Klassisch": {
      desc: "Heller Glockenanschlag, ausgewogen",
      partials: [[1, 1], [2.0, 0.5], [3.0, 0.34], [4.2, 0.18]],
      base: 330, decay: 2.2, strike: 0.5, hue: "#8C5A2E",
    },
    "Tiefe Resonanz": {
      desc: "Sehr tief, sphärisch, langer Nachhall",
      partials: [[1, 1], [1.9, 0.45], [3.3, 0.2], [4.8, 0.1]],
      base: 104, decay: 5.0, strike: 0.4, hue: "#6E4B3A",
    },
    "Klarer Anschlag": {
      desc: "Trocken, präzise, kurz",
      partials: [[1, 1], [2.4, 0.4], [4.9, 0.18]],
      base: 520, decay: 1.1, strike: 0.85, hue: "#B5713F",
    },
  };
  const TONE_ORDER = ["Tempelglocke", "Klangschale", "Klassisch", "Tiefe Resonanz", "Klarer Anschlag"];

  /* ---- Voice-bed waveform: synthesized "guided meditation" speech envelope.
     Speech bursts (phrases) separated by breathing pauses. We model the
     per-frame amplitude so we can (a) draw it and (b) compute its RMS. ---- */
  function makeVoiceModel(n = 96, seed = 7) {
    let s = seed;
    const rnd = () => (s = (s * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff;
    const amp = new Array(n).fill(0);
    let i = 0;
    while (i < n) {
      // pause
      const pause = 2 + Math.floor(rnd() * 4);
      for (let k = 0; k < pause && i < n; k++, i++) amp[i] = 0.02 + rnd() * 0.03;
      // phrase
      const len = 5 + Math.floor(rnd() * 11);
      const peak = 0.42 + rnd() * 0.36;
      for (let k = 0; k < len && i < n; k++, i++) {
        const env = Math.sin((k / len) * Math.PI); // rise+fall over phrase
        const syll = 0.55 + 0.45 * Math.abs(Math.sin(k * 1.7 + rnd())); // syllable ripple
        amp[i] = Math.max(amp[i], peak * env * syll + rnd() * 0.05);
      }
    }
    // RMS over the speaking frames (ignore near-silence)
    const speaking = amp.filter((a) => a > 0.12);
    const rms = Math.sqrt(speaking.reduce((q, a) => q + a * a, 0) / Math.max(1, speaking.length));
    const peak = Math.max(...amp);
    return { amp, rms, peak };
  }

  /* Auto gong level derived from the voice RMS.
     We want the gong peak to sit a touch above average speech so it is clearly
     audible without startling. baseFactor ~ voice RMS * 2.0 (~ +6 dB).
     `trim` is the user's fine offset in dB (−9..+9), 0 = pure auto. */
  function autoGongLevel(voiceRms, trimDb = 0) {
    const baseLin = Math.min(0.98, voiceRms * 2.0);
    const lin = baseLin * Math.pow(10, trimDb / 20);
    return Math.max(0.05, Math.min(1, lin));
  }

  /* ---- Play one gong strike at linear gain `level` (0..1) ---- */
  let activeNodes = [];
  function stopAll() {
    const a = ac();
    activeNodes.forEach((g) => {
      try { g.gain.cancelScheduledValues(a.currentTime); g.gain.setTargetAtTime(0, a.currentTime, 0.05); } catch (e) {}
    });
    activeNodes = [];
  }

  function playGong(toneId, level = 0.6) {
    const a = ac();
    const t0 = a.currentTime;
    const T = TONES[toneId] || TONES["Tempelglocke"];
    const out = a.createGain();
    out.gain.value = Math.max(0.0001, level) * 0.9;
    out.connect(a.destination);
    activeNodes.push(out);

    // soft strike transient
    const noiseLen = 0.04;
    const buf = a.createBuffer(1, Math.floor(a.sampleRate * noiseLen), a.sampleRate);
    const d = buf.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = (Math.random() * 2 - 1) * (1 - i / d.length);
    const noise = a.createBufferSource(); noise.buffer = buf;
    const nf = a.createBiquadFilter(); nf.type = "bandpass"; nf.frequency.value = T.base * 3; nf.Q.value = 0.8;
    const ng = a.createGain(); ng.gain.value = T.strike * 0.5;
    noise.connect(nf).connect(ng).connect(out);
    noise.start(t0); noise.stop(t0 + noiseLen);

    // partials
    T.partials.forEach(([mult, gainMul], idx) => {
      const osc = a.createOscillator();
      osc.type = "sine";
      osc.frequency.value = T.base * mult;
      const g = a.createGain();
      const decay = T.decay * (1 - idx * 0.13);
      g.gain.setValueAtTime(0, t0);
      g.gain.linearRampToValueAtTime(gainMul, t0 + 0.008);
      g.gain.exponentialRampToValueAtTime(0.0008, t0 + decay);
      osc.connect(g).connect(out);
      osc.start(t0);
      osc.stop(t0 + decay + 0.1);
    });
    return T.decay;
  }

  /* ---- Voice bed: filtered noise shaped by the voice amplitude model.
     Used in the "Im Mix anhören" preview so the user hears the gong AT the
     derived level sitting over the spoken voice. Returns a stop() fn. ---- */
  function playVoiceBed(model, durationSec, onTick) {
    const a = ac();
    const t0 = a.currentTime;
    const src = a.createBufferSource();
    const len = Math.floor(a.sampleRate * durationSec);
    const buf = a.createBuffer(1, len, a.sampleRate);
    const d = buf.getChannelData(0);
    const n = model.amp.length;
    for (let i = 0; i < len; i++) {
      const frame = Math.min(n - 1, Math.floor((i / len) * n));
      const env = model.amp[frame];
      // voiced buzz ~ 130 Hz + noise, scaled by env
      const tt = i / a.sampleRate;
      const buzz = Math.sin(2 * Math.PI * 128 * tt) * 0.5 + (Math.random() * 2 - 1) * 0.5;
      d[i] = buzz * env * 0.5;
    }
    src.buffer = buf;
    const lp = a.createBiquadFilter(); lp.type = "lowpass"; lp.frequency.value = 1800;
    const vg = a.createGain(); vg.gain.value = 0.7;
    src.connect(lp).connect(vg).connect(a.destination);
    src.start(t0);
    activeNodes.push(vg);

    let raf;
    const tick = () => {
      const p = (a.currentTime - t0) / durationSec;
      if (p >= 1) { onTick && onTick(1, true); return; }
      onTick && onTick(p, false);
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => { try { src.stop(); } catch (e) {} cancelAnimationFrame(raf); };
  }

  window.GongAudio = {
    TONES, TONE_ORDER,
    makeVoiceModel, autoGongLevel,
    playGong, playVoiceBed, stopAll, ac,
  };
})();
