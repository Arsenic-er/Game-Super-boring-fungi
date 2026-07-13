from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
OUT = ROOT / "font-candidates-ui.png"

FONTS = [
    (
        "A  方舟像素 / Ark Pixel 12px",
        ROOT / "downloads/ark/ark-pixel-12px-proportional-zh_cn.ttf",
        "清晰、均衡，适合长期阅读",
    ),
    (
        "B  缝合像素 / Fusion Pixel 12px",
        ROOT / "downloads/fusion/fusion-pixel-12px-proportional-zh_hans.ttf",
        "经典游戏感，字形覆盖最稳妥",
    ),
    (
        "C  缝合粗像素 / Fusion Bold 12px",
        ROOT / "downloads/fusion-bold/fusion-bold-pixel-12px-proportional-zh_hans.ttf",
        "圆钝厚实，按钮和标题更可爱",
    ),
    (
        "D  精品点阵体 7×7 / BoutiqueBitmap",
        ROOT / "downloads/boutique7/BoutiqueBitmap7x7_1.71.ttf",
        "颗粒最强，偏掌机与复古童趣",
    ),
]


def load_font(path: Path, size: int = 12) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(path), size=size)


def main() -> None:
    scale = 2
    width, height = 800, 522
    image = Image.new("RGB", (width, height), "#061326")
    draw = ImageDraw.Draw(image)

    # Header intentionally uses candidate A only as a neutral pixel label.
    header_font = load_font(FONTS[0][1], 12)
    draw.rectangle((0, 0, width, 44), fill="#0a2034")
    draw.text((18, 12), "真菌微观章节 · 中文像素 UI 字体候选", font=header_font, fill="#d9f0e8")
    draw.text((530, 12), "请回复 A / B / C / D", font=header_font, fill="#7fe0bd")

    panel_top = 54
    panel_height = 111
    for index, (name, font_path, note) in enumerate(FONTS):
        font = load_font(font_path, 12)
        y = panel_top + index * 116
        draw.rectangle((12, y, width - 12, y + panel_height), fill="#081b2d", outline="#397a72", width=1)
        draw.rectangle((20, y + 10, 370, y + 34), fill="#0b2b38", outline="#6fc7a5", width=1)
        draw.text((28, y + 16), name, font=font, fill="#e2f5ec")
        draw.text((398, y + 16), note, font=font, fill="#8db5ae")

        draw.rectangle((20, y + 43, width - 20, y + 68), fill="#061522", outline="#244b50", width=1)
        draw.rectangle((29, y + 52, 32, y + 55), fill="#58b8df")
        draw.text(
            (39, y + 49),
            "水分 ∞   有机营养 223.375   矿物 23.000   DNA 1",
            font=font,
            fill="#d7ebe6",
        )

        draw.rectangle((20, y + 77, 374, y + 102), fill="#071a26", outline="#b9f2cf", width=1)
        draw.text((29, y + 83), "延伸主菌丝  有机营养 1.000 / 11 μm", font=font, fill="#b9f2cf")
        draw.rectangle((388, y + 77, width - 20, y + 102), fill="#071a26", outline="#f3b562", width=1)
        draw.text((397, y + 83), "形成孢子核  70.000 + 矿物 6.000", font=font, fill="#f3b562")

    # Upscale by an integer with nearest-neighbor to preserve exact pixels.
    image = image.resize((width * scale, height * scale), Image.Resampling.NEAREST)
    image.save(OUT)
    print(OUT.name)


if __name__ == "__main__":
    main()
