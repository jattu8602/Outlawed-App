from PIL import Image, ImageChops, ImageOps

def optimize_logo(input_path, output_path, padding_ratio=0.30, shave_px=3):
    img = Image.open(input_path).convert("RGBA")

    # 1. Smart Crop (Threshold)
    # Convert to grayscale
    gray = img.convert("L")

    # Invert so content is bright, white bg is dark
    inverted = ImageOps.invert(gray)

    # Threshold white pixels (original > 240) to black (0)
    threshold = 15
    mask = inverted.point(lambda p: 255 if p > threshold else 0)

    # Get bounding box of explicit content
    bbox = mask.getbbox()

    if bbox:
        # Shave edges to remove 1-pixel border artifacts
        left, top, right, bottom = bbox
        left = min(left + shave_px, right)
        top = min(top + shave_px, bottom)
        right = max(right - shave_px, left)
        bottom = max(bottom - shave_px, top)

        print(f"Original bbox: {bbox}")
        print(f"Shaved bbox: {(left, top, right, bottom)}")

        img_cropped = img.crop((left, top, right, bottom))
    else:
        print("Could not detect content! Using original.")
        img_cropped = img

    # 2. Add controlled padding
    w, h = img_cropped.size
    max_dim = max(w, h)

    # Calculated square canvas side
    canvas_side = int(max_dim * (1 + 2 * padding_ratio))

    # Transparent BG for Adaptive Icon Foreground
    bg_color = (255, 255, 255, 0)

    new_img = Image.new("RGBA", (canvas_side, canvas_side), bg_color)

    # Center content
    offset_x = (canvas_side - w) // 2
    offset_y = (canvas_side - h) // 2

    new_img.paste(img_cropped, (offset_x, offset_y))

    new_img.save(output_path)
    print(f"Saved optimized logo to {output_path}")

if __name__ == "__main__":
    # Padding 0.45 shrinks the logo further (zooms out)
    optimize_logo("assets/images/logo.png", "assets/images/logo_optimized.png", padding_ratio=0.45, shave_px=5)
