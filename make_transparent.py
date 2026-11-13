import sys
from PIL import Image

def remove_white_background(image_path, output_path, tolerance=20):
    img = Image.open(image_path).convert("RGBA")
    datas = img.getdata()
    
    newData = []
    # Loop through every pixel
    for item in datas:
        # Check if pixel is close to white (255, 255, 255)
        if item[0] >= 255 - tolerance and item[1] >= 255 - tolerance and item[2] >= 255 - tolerance:
            # Replace with transparent pixel
            newData.append((255, 255, 255, 0))
        else:
            newData.append(item)
            
    img.putdata(newData)
    
    # Crop to content box
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        
    img.save(output_path, "PNG")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python make_transparent.py <input> <output>")
        sys.exit(1)
        
    in_path = sys.argv[1]
    out_path = sys.argv[2]
    
    try:
        remove_white_background(in_path, out_path, tolerance=15)
        print(f"Successfully processed {in_path} -> {out_path}")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
