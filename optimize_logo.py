from PIL import Image, ImageChops, ImageOps

def optimize_logo(input_path, output_path, padding_ratio=0.15):
    img = Image.open(input_path).convert("RGBA")

    # 1. More aggressive crop with tolerance
    # Convert to grayscale to check brightness
    gray = img.convert("L")

    # Invert so content is bright, white bg is dark
    # Note: If logo is black on white, white->255, black->0.
    # Invert: white->0, black->255.
    inverted = ImageOps.invert(gray)

    # Threshold: anything "near white" (originally > 240) becomes 0 in inverted
    # So if inverted pixel < 15 (original > 240), make it 0
    threshold = 15
    mask = inverted.point(lambda p: 255 if p > threshold else 0)

    bbox = mask.getbbox()

    if bbox:
        print(f"Original size: {img.size}")
        img_cropped = img.crop(bbox)
        print(f"Smart cropped size: {img_cropped.size} (bbox: {bbox})")
    else:
        print("Could not detect content! Using original.")
        img_cropped = img

    # 2. Pad
    w, h = img_cropped.size
    max_dim = max(w, h)
    canvas_side = int(max_dim * (1 + 2 * padding_ratio))

    # White BG
    bg_color = (255, 255, 255, 255)
    new_img = Image.new("RGBA", (canvas_side, canvas_side), bg_color)

    offset_x = (canvas_side - w) // 2
    offset_y = (canvas_side - h) // 2

    new_img.paste(img_cropped, (offset_x, offset_y))

    new_img.save(output_path)
    print(f"Saved optimized logo to {output_path}")

if __name__ == "__main__":
    optimize_logo("assets/images/logo.png", "assets/images/logo_optimized.png", padding_ratio=0.30)
