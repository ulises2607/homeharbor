"""Build an explicitly edited, captioned walkthrough from authentic screenshots.

Tools: Python 3, Pillow and imageio-ffmpeg. Outputs are private build artifacts,
not source assets; screenshots are never overwritten.
"""
from pathlib import Path
import json
import subprocess
import textwrap

from PIL import Image, ImageDraw, ImageFont
import imageio_ffmpeg

HERE = Path(__file__).resolve().parent
OUTPUT = HERE.parents[1] / "artifacts" / "demo"
OUTPUT.mkdir(parents=True, exist_ok=True)
SCENES = json.loads((HERE / "scenes.json").read_text(encoding="utf-8"))
FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
FONT_PATHS = [
    Path("C:/Windows/Fonts/arial.ttf"),
    Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
    Path("/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf"),
]
FONT = next((path for path in FONT_PATHS if path.exists()), None)
if FONT is None:
    raise SystemExit("Install Arial, DejaVu Sans or Liberation Sans to render captions.")


def font(size):
    return ImageFont.truetype(str(FONT), size)


def fit(image, width, height):
    image = image.convert("RGB")
    image.thumbnail((width, height), Image.Resampling.LANCZOS)
    return image


def render(scene, language, index):
    canvas = Image.new("RGB", (1920, 1080), "#f3f5ef")
    draw = ImageDraw.Draw(canvas)
    draw.text((72, 35), "HOMEHARBOR", font=font(28), fill="#17645c")
    draw.text((72, 79), scene[language][0], font=font(40), fill="#173c43")
    draw.text((1740, 55), f"{index + 1:02d} / 07", font=font(25), fill="#506b69")
    files = [scene["file"]] + ([scene["second"]] if "second" in scene else [])
    for slot, name in enumerate(files):
        image = fit(Image.open(HERE / "screenshots" / name), 1640 if len(files) == 1 else 740, 780)
        center = 960 if len(files) == 1 else (660 if slot == 0 else 1260)
        canvas.paste(image, (center - image.width // 2, 148 + (780 - image.height) // 2))
    caption = scene[language][1]
    draw.text((72, 954), caption, font=font(29), fill="#173c43")
    footer = (
        "Demo de portfolio · Datos ficticios · Montaje de capturas reales · Evolución de Reserve Boats / Microverse"
        if language == "es" else
        "Portfolio demo · Fictional data · Edited authentic screenshots · Based on Reserve Boats / Microverse"
    )
    draw.text((72, 1010), footer, font=font(21), fill="#506b69")
    return canvas


for language in ("es", "en"):
    clips = []
    for index, scene in enumerate(SCENES):
        frame = OUTPUT / f"{language}-{index + 1:02d}.png"
        render(scene, language, index).save(frame)
        if index == 0 and language == "es":
            render(scene, language, index).save(OUTPUT / "homeharbor-cover.png")
        clip = OUTPUT / f"{language}-{index + 1:02d}.mp4"
        command = [
            FFMPEG, "-y", "-loglevel", "error", "-loop", "1", "-i", str(frame),
            "-t", "8", "-r", "24", "-vf", "fade=t=in:st=0:d=0.25,fade=t=out:st=7.75:d=0.25",
            "-c:v", "libx264", "-preset", "fast", "-crf", "20", "-pix_fmt", "yuv420p",
            "-an", str(clip),
        ]
        subprocess.run(command, check=True)
        clips.append(clip)
    manifest = OUTPUT / f"{language}-clips.txt"
    manifest.write_text("\n".join(f"file '{clip.name}'" for clip in clips), encoding="utf-8")
    target = OUTPUT / f"homeharbor-demo-{language}.mp4"
    subprocess.run([
        FFMPEG, "-y", "-loglevel", "error", "-f", "concat", "-safe", "0",
        "-i", str(manifest), "-c", "copy", "-movflags", "+faststart", str(target),
    ], check=True)
    # Decode the full result, catching corrupted or truncated encodes.
    subprocess.run([FFMPEG, "-v", "error", "-i", str(target), "-f", "null", "-"], check=True)
    print(f"Verified: {target.name} ({target.stat().st_size:,} bytes, 56 seconds)")
