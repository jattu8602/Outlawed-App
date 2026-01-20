from PIL import Image

def add_margin(input_path, output_path, margin_ratio=0.3):
    img = Image.open(input_path)
    img = img.convert("RGBA")
    w, h = img.size

    # Calculate new size based on margin
    # If we want the logo to look smaller (more margin), we make the canvas bigger
    new_w = int(w * (1 + margin_ratio))
    new_h = int(h * (1 + margin_ratio))

    # Determine background color from top-left pixel
    # If alpha is 0, use transparent. Else use the color.
    bg_color = (255, 255, 255, 0) # Default transparent

    # Check corner for background color
    corner = img.getpixel((0, 0))
    if corner[3] > 0: # If not transparent
        bg_color = corner

    # Create new background
    new_img = Image.new("RGBA", (new_w, new_h), bg_color)

    # Paste original in center
    offset_x = (new_w - w) // 2
    offset_y = (new_h - h) // 2
    new_img.paste(img, (offset_x, offset_y), img)

    new_img.save(output_path)
    print(f"Saved padded logo to {output_path}")

if __name__ == "__main__":
    add_margin("assets/images/logo.png", "assets/images/logo_padded.png", margin_ratio=0.25)
