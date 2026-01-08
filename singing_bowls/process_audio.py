#!/usr/bin/env python3
"""
Audio-Prozessor für Klangschalen-Sounds.

- Entfernt Stille am Anfang
- Kürzt auf n Sekunden
- Fügt Fade-out hinzu
- Normalisiert Lautstärke (-16 LUFS)
"""

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass
class AudioConfig:
    """Konfiguration für die Audio-Verarbeitung."""
    target_duration: float = 10.0
    fade_duration: float = 2.0
    target_lufs: float = -16.0
    true_peak: float = -1.5
    silence_threshold_db: float = -50.0
    min_silence_duration: float = 0.1
    output_dir: str = "processed"
    bitrate: str = "192k"


@dataclass
class AudioAnalysis:
    """Ergebnis der Audio-Analyse."""
    duration: float
    silence_end: float | None
    effective_duration: float


@dataclass
class ProcessingResult:
    """Ergebnis der Verarbeitung."""
    output_path: Path
    duration: float
    lufs: float
    true_peak: float
    silence_removed: float


def run_ffmpeg(args: list[str], capture_stderr: bool = False) -> str:
    """Führt ffmpeg aus und gibt stdout/stderr zurück."""
    try:
        result = subprocess.run(
            ["ffmpeg"] + args,
            capture_output=True,
            text=True,
            check=False,
        )
        return result.stderr if capture_stderr else result.stdout
    except FileNotFoundError:
        sys.exit("Fehler: ffmpeg nicht gefunden. Bitte installieren.")


def run_ffprobe(args: list[str]) -> str:
    """Führt ffprobe aus und gibt stdout zurück."""
    try:
        result = subprocess.run(
            ["ffprobe"] + args,
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout
    except FileNotFoundError:
        sys.exit("Fehler: ffprobe nicht gefunden. Bitte installieren.")


def get_duration(file_path: Path) -> float:
    """Ermittelt die Dauer einer Audio-Datei in Sekunden."""
    output = run_ffprobe([
        "-v", "quiet",
        "-show_entries", "format=duration",
        "-of", "json",
        str(file_path)
    ])
    data = json.loads(output)
    return float(data["format"]["duration"])


def detect_silence(file_path: Path, config: AudioConfig) -> float | None:
    """Erkennt Stille am Anfang und gibt das Ende der Stille zurück."""
    output = run_ffmpeg([
        "-i", str(file_path),
        "-af", f"silencedetect=noise={config.silence_threshold_db}dB:d={config.min_silence_duration}",
        "-f", "null", "-"
    ], capture_stderr=True)

    # Suche nach erstem silence_end (Stille am Anfang)
    match = re.search(r"silence_end: ([\d.]+)", output)
    if match:
        silence_end = float(match.group(1))
        # Nur relevant wenn > 0.5s
        if silence_end > 0.5:
            return silence_end
    return None


def analyze_audio(file_path: Path, config: AudioConfig) -> AudioAnalysis:
    """Analysiert eine Audio-Datei."""
    duration = get_duration(file_path)
    silence_end = detect_silence(file_path, config)

    effective_duration = duration
    if silence_end:
        effective_duration = duration - silence_end

    return AudioAnalysis(
        duration=duration,
        silence_end=silence_end,
        effective_duration=effective_duration,
    )


def measure_loudness(file_path: Path) -> tuple[float, float]:
    """Misst LUFS und True Peak einer Audio-Datei."""
    output = run_ffmpeg([
        "-i", str(file_path),
        "-af", "loudnorm=I=-16:print_format=summary",
        "-f", "null", "-"
    ], capture_stderr=True)

    lufs_match = re.search(r"Input Integrated:\s+([-\d.]+)", output)
    tp_match = re.search(r"Input True Peak:\s+([-\d.]+)", output)

    lufs = float(lufs_match.group(1)) if lufs_match else float("-inf")
    true_peak = float(tp_match.group(1)) if tp_match else float("-inf")

    return lufs, true_peak


def build_filter_chain(analysis: AudioAnalysis, config: AudioConfig) -> str:
    """Baut die FFmpeg Filter-Kette zusammen."""
    filters = []

    # 1. Trim (Stille entfernen und/oder kürzen)
    trim_start = analysis.silence_end or 0
    if analysis.effective_duration > config.target_duration:
        filters.append(f"atrim=start={trim_start}:duration={config.target_duration}")
        final_duration = config.target_duration
    else:
        if trim_start > 0:
            filters.append(f"atrim=start={trim_start}")
        final_duration = analysis.effective_duration

    # 2. Timestamps zurücksetzen (wichtig nach trim)
    filters.append("asetpts=PTS-STARTPTS")

    # 3. Fade-out
    fade_duration = min(config.fade_duration, final_duration)
    fade_start = max(0, final_duration - fade_duration)
    filters.append(f"afade=t=out:st={fade_start}:d={fade_duration}")

    # 4. Loudness-Normalisierung
    filters.append(
        f"loudnorm=I={config.target_lufs}:TP={config.true_peak}:LRA=11"
    )

    return ",".join(filters)


def process_file(input_path: Path, config: AudioConfig) -> ProcessingResult:
    """Verarbeitet eine einzelne Audio-Datei."""
    # Output-Pfad
    output_dir = input_path.parent / config.output_dir
    output_dir.mkdir(exist_ok=True)
    output_path = output_dir / input_path.name

    # Analyse
    analysis = analyze_audio(input_path, config)

    # Filter bauen
    filter_chain = build_filter_chain(analysis, config)

    # Verarbeiten
    run_ffmpeg([
        "-y",
        "-i", str(input_path),
        "-af", filter_chain,
        "-c:a", "libmp3lame",
        "-b:a", config.bitrate,
        str(output_path)
    ])

    # Ergebnis messen
    result_duration = get_duration(output_path)
    lufs, true_peak = measure_loudness(output_path)

    return ProcessingResult(
        output_path=output_path,
        duration=result_duration,
        lufs=lufs,
        true_peak=true_peak,
        silence_removed=analysis.silence_end or 0,
    )


def main():
    parser = argparse.ArgumentParser(
        description="Audio-Prozessor für Klangschalen-Sounds",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Beispiele:
  %(prog)s klangschale.mp3              # 10s, 2s fade
  %(prog)s klangschale.mp3 -d 15        # 15s, 2s fade
  %(prog)s klangschale.mp3 -d 10 -f 3   # 10s, 3s fade
  %(prog)s *.mp3                        # Alle MP3s verarbeiten
        """
    )
    parser.add_argument("files", nargs="+", type=Path, help="Audio-Datei(en)")
    parser.add_argument("-d", "--duration", type=float, default=10.0,
                        help="Ziel-Länge in Sekunden (default: 10)")
    parser.add_argument("-f", "--fade", type=float, default=2.0,
                        help="Fade-out Dauer in Sekunden (default: 2)")
    parser.add_argument("-l", "--lufs", type=float, default=-16.0,
                        help="Ziel-LUFS (default: -16)")
    parser.add_argument("-o", "--output", type=str, default="processed",
                        help="Output-Verzeichnis (default: processed)")

    args = parser.parse_args()

    config = AudioConfig(
        target_duration=args.duration,
        fade_duration=args.fade,
        target_lufs=args.lufs,
        output_dir=args.output,
    )

    print(f"Ziel: {config.target_duration}s mit {config.fade_duration}s Fade-out\n")

    results = []
    for file_path in args.files:
        if not file_path.exists():
            print(f"Überspringe: {file_path} (nicht gefunden)")
            continue
        if not file_path.suffix.lower() == ".mp3":
            print(f"Überspringe: {file_path} (kein MP3)")
            continue

        print(f"Verarbeite: {file_path.name}")

        try:
            result = process_file(file_path, config)
            results.append(result)

            silence_info = ""
            if result.silence_removed > 0:
                silence_info = f", {result.silence_removed:.1f}s Stille entfernt"

            print(f"  → {result.duration:.1f}s | {result.lufs:.1f} LUFS | "
                  f"{result.true_peak:.1f} dBTP{silence_info}")
        except Exception as e:
            print(f"  Fehler: {e}")

    if results:
        print(f"\n{len(results)} Datei(en) verarbeitet → {config.output_dir}/")


if __name__ == "__main__":
    main()
