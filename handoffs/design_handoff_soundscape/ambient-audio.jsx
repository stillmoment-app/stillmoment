/* ambient-audio.jsx — WebAudio synthesis of looping background soundscapes for
   the prototype's preview. These are NOISE-BASED approximations so the reviewer
   hears *something* characteristic per scape.

   IN THE APP: replace with the real looping ambience audio files (Wald, Regen,
   …) and the user's imported files. Only ONE scape plays at a time; volume maps
   to the slider (0..100). */

(function () {
  let ctx = null;
  function ac() {
    if (!ctx) ctx = new (window.AudioContext || window.webkitAudioContext)();
    if (ctx.state === "suspended") ctx.resume();
    return ctx;
  }

  /* ---- Noise buffer generators ---- */
  function noiseBuffer(a, seconds, type) {
    const len = Math.floor(a.sampleRate * seconds);
    const buf = a.createBuffer(1, len, a.sampleRate);
    const d = buf.getChannelData(0);
    if (type === "brown") {
      let last = 0;
      for (let i = 0; i < len; i++) {
        const w = Math.random() * 2 - 1;
        last = (last + 0.02 * w) / 1.02;
        d[i] = last * 3.5;
      }
    } else if (type === "pink") {
      let b0 = 0, b1 = 0, b2 = 0;
      for (let i = 0; i < len; i++) {
        const w = Math.random() * 2 - 1;
        b0 = 0.99765 * b0 + w * 0.0990460;
        b1 = 0.96300 * b1 + w * 0.2965164;
        b2 = 0.57000 * b2 + w * 1.0526913;
        d[i] = (b0 + b1 + b2 + w * 0.1848) * 0.22;
      }
    } else {
      for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
    }
    return buf;
  }

  let active = null; // { nodes: [], gain }

  function stopAll() {
    if (!active) return;
    const a = ac();
    const { nodes, gain } = active;
    try { gain.gain.cancelScheduledValues(a.currentTime); gain.gain.setTargetAtTime(0, a.currentTime, 0.18); } catch (e) {}
    setTimeout(() => nodes.forEach((n) => { try { n.stop(); } catch (e) {} }), 450);
    active = null;
  }

  function gainFor(level) { return Math.max(0.0001, level) * 0.55; }

  function play(id, level = 0.6) {
    stopAll();
    const a = ac();
    const t0 = a.currentTime;
    const out = a.createGain();
    out.gain.value = 0;
    out.connect(a.destination);
    out.gain.setTargetAtTime(gainFor(level), t0, 0.25);
    const nodes = [];

    if (id === "Regen") {
      // bright hiss
      const hiss = a.createBufferSource(); hiss.buffer = noiseBuffer(a, 3, "white"); hiss.loop = true;
      const hp = a.createBiquadFilter(); hp.type = "highpass"; hp.frequency.value = 1000;
      const lp = a.createBiquadFilter(); lp.type = "lowpass"; lp.frequency.value = 8500;
      const hg = a.createGain(); hg.gain.value = 0.7;
      hiss.connect(hp).connect(lp).connect(hg).connect(out); hiss.start(t0); nodes.push(hiss);
      // low body / patter
      const body = a.createBufferSource(); body.buffer = noiseBuffer(a, 3, "brown"); body.loop = true;
      const blp = a.createBiquadFilter(); blp.type = "lowpass"; blp.frequency.value = 480;
      const bg = a.createGain(); bg.gain.value = 0.5;
      body.connect(blp).connect(bg).connect(out); body.start(t0); nodes.push(body);
    } else if (id === "Waldatmosphäre") {
      // low wind bed with a slow filter sweep
      const wind = a.createBufferSource(); wind.buffer = noiseBuffer(a, 4, "brown"); wind.loop = true;
      const lp = a.createBiquadFilter(); lp.type = "lowpass"; lp.frequency.value = 420;
      const lfo = a.createOscillator(); lfo.frequency.value = 0.08;
      const lfg = a.createGain(); lfg.gain.value = 170;
      lfo.connect(lfg).connect(lp.frequency); lfo.start(t0); nodes.push(lfo);
      wind.connect(lp).connect(out); wind.start(t0); nodes.push(wind);
      // airy leaves
      const air = a.createBufferSource(); air.buffer = noiseBuffer(a, 4, "pink"); air.loop = true;
      const bp = a.createBiquadFilter(); bp.type = "bandpass"; bp.frequency.value = 2400; bp.Q.value = 0.4;
      const ag = a.createGain(); ag.gain.value = 0.07;
      air.connect(bp).connect(ag).connect(out); air.start(t0); nodes.push(air);
    } else {
      // unknown / imported file — neutral soft pink-noise bed
      const src = a.createBufferSource(); src.buffer = noiseBuffer(a, 4, "pink"); src.loop = true;
      const lp = a.createBiquadFilter(); lp.type = "lowpass"; lp.frequency.value = 1600;
      src.connect(lp).connect(out); src.start(t0); nodes.push(src);
    }

    active = { nodes: [...nodes, out], gain: out, id };
    return out;
  }

  function setLevel(level) {
    if (!active) return;
    const a = ac();
    try { active.gain.gain.setTargetAtTime(gainFor(level), a.currentTime, 0.12); } catch (e) {}
  }

  function playingId() { return active ? active.id : null; }

  window.AmbientAudio = { play, stopAll, setLevel, playingId, ac };
})();
