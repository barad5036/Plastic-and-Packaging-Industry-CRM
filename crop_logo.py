import sys
from PIL import Image, ImageChops

def trim(im):
    # Find the bounding box of the non-white pixels
    bg = Image.new(im.mode, im.size, im.getpixel((0,0)))
    diff = ImageChops.difference(im, bg)
    diff = ImageChops.add(diff, diff, 2.0, -100)
    bbox = diff.getbbox()
    if bbox:
        # add a small padding (e.g., 5%)
        pad = int((bbox[2] - bbox[0]) * 0.05)
        new_bbox = (
            max(0, bbox[0] - pad),
            max(0, bbox[1] - pad),
            min(im.size[0], bbox[2] + pad),
            min(im.size[1], bbox[3] + pad)
        )
        return im.crop(new_bbox)
    return im

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python crop_logo.py <path_to_image>")
        sys.exit(1)
        
    image_path = sys.argv[1]
    
    try:
        im = Image.open(image_path)
        
        # Convert to RGBA if not already
        if im.mode != 'RGBA':
            im = im.convert('RGBA')
            
        # Also let's try to remove white background and make it transparent just in case
        # But actually for app icons, typically we want a solid background or just the cropped image
        # Let's just crop to the bounds of the actual logo first based on top-left pixel color.
        
        cropped_im = trim(im)
        
        # Resize it back to a good square size for launcher icons, e.g. 1024x1024
        # We need it to be square.
        width, height = cropped_im.size
        size = max(width, height)
        # Add a 10% padding to everything
        pad = int(size * 0.1)
        new_size = size + 2 * pad
        
        # Create a white background square image
        square_im = Image.new('RGBA', (new_size, new_size), (255, 255, 255, 255))
        
        # Paste the cropped image in the center
        paste_x = (new_size - width) // 2
        paste_y = (new_size - height) // 2
        
        # If the cropped image has transparency, use it as a mask
        if 'A' in cropped_im.mode:
            square_im.paste(cropped_im, (paste_x, paste_y), cropped_im)
        else:
            square_im.paste(cropped_im, (paste_x, paste_y))
            
        square_im.save(image_path)
        print("Successfully cropped and formatted the logo.")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
