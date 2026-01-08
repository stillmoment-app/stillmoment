#!/usr/bin/env python3
"""Display audio file information for singing bowl sounds."""

import json
import re
import subprocess
import sys
from pathlib import Path


def get_loudness(file_path: Path) -> tuple[float | None, float | None]:
    """Get LUFS and True Peak using ffmpeg loudnorm."""
    try:
        result = subprocess.run(
            [
                "ffmpeg",
                "-i", str(file_path),
                "-af", "loudnorm=I=-16:print_format=summary",
                "-f", "null", "-",
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        output = result.stderr

        lufs_match = re.search(r"Input Integrated:\s+([-\d.]+)", output)
        tp_match = re.search(r"Input True Peak:\s+([-\d.]+)", output)

        lufs = float(lufs_match.group(1)) if lufs_match else None
        true_peak = float(tp_match.group(1)) if tp_match else None

        return lufs, true_peak
    except Exception:
        return None, None


def get_audio_info(file_path: Path) -> dict | None:
    """Get audio metadata using ffprobe."""
    try:
        result = subprocess.run(
            [
                "ffprobe",
                "-v", "quiet",
                "-print_format", "json",
                "-show_format",
                "-show_streams",
                str(file_path),
            ],
            capture_output=True,
            text=True,
            check=True,
        )
        return json.loads(result.stdout)
    except (subprocess.CalledProcessError, json.JSONDecodeError):
        return None


def format_duration(seconds: float) -> str:
    """Format duration as mm:ss.ms."""
    mins = int(seconds // 60)
    secs = seconds % 60
    return f"{mins}:{secs:05.2f}"


def format_size(bytes_size: int) -> str:
    """Format file size in human-readable form."""
    if bytes_size >= 1024 * 1024:
        return f"{bytes_size / (1024 * 1024):.1f} MB"
    return f"{bytes_size / 1024:.0f} KB"


def print_file_info(file_path: Path, indent: str = "", show_loudness: bool = False) -> None:
    """Print formatted info for a single audio file."""
    info = get_audio_info(file_path)
    if not info:
        print(f"{indent}{file_path.name}: (unable to read)")
        return

    # Extract stream info (first audio stream)
    audio_stream = next(
        (s for s in info.get("streams", []) if s.get("codec_type") == "audio"),
        {},
    )

    # Extract format info
    fmt = info.get("format", {})

    duration = float(fmt.get("duration", 0))
    bit_rate = int(fmt.get("bit_rate", 0)) // 1000  # kbps
    sample_rate = int(audio_stream.get("sample_rate", 0))
    channels = audio_stream.get("channels", 0)
    channel_str = "mono" if channels == 1 else "stereo" if channels == 2 else f"{channels}ch"
    file_size = file_path.stat().st_size

    # Loudness measurement (optional, slower)
    lufs_str = ""
    tp_str = ""
    if show_loudness:
        lufs, true_peak = get_loudness(file_path)
        lufs_str = f"{lufs:>6.1f} LUFS  " if lufs else "     - LUFS  "
        tp_str = f"{true_peak:>5.1f} dBTP  " if true_peak else "    - dBTP  "

    print(
        f"{indent}{file_path.name:<45} "
        f"{format_duration(duration):>8}  "
        f"{sample_rate:>5} Hz  "
        f"{bit_rate:>3} kbps  "
        f"{channel_str:<6}  "
        f"{lufs_str}{tp_str}"
        f"{format_size(file_size):>8}"
    )


def main() -> None:
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(description="Display audio file information")
    parser.add_argument("-l", "--loudness", action="store_true",
                        help="Show LUFS and True Peak (slower)")
    args = parser.parse_args()

    base_dir = Path(__file__).parent
    processed_dir = base_dir / "processed"

    # Collect audio files
    audio_extensions = {".mp3", ".wav", ".m4a", ".aac", ".ogg", ".flac"}
    original_files = sorted(
        f for f in base_dir.iterdir()
        if f.is_file() and f.suffix.lower() in audio_extensions
    )
    processed_files = sorted(
        f for f in processed_dir.iterdir()
        if f.is_file() and f.suffix.lower() in audio_extensions
    ) if processed_dir.exists() else []

    # Build header
    width = 135 if args.loudness else 110
    loudness_header = "    LUFS     Peak  " if args.loudness else ""

    print("=" * width)
    print("SINGING BOWL AUDIO FILES")
    print("=" * width)
    print(
        f"{'File':<45} {'Duration':>8}  "
        f"{'Sample':>8}  {'Rate':>8}  {'Ch':<6}  "
        f"{loudness_header}{'Size':>8}"
    )
    print("-" * width)

    # Original files
    if original_files:
        print("\n[Original Files]")
        for f in original_files:
            print_file_info(f, show_loudness=args.loudness)

    # Processed files
    if processed_files:
        print("\n[Processed Files]")
        for f in processed_files:
            print_file_info(f, "  ", show_loudness=args.loudness)

    print("-" * width)
    print(f"Total: {len(original_files)} original, {len(processed_files)} processed")


if __name__ == "__main__":
    main()
