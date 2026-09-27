from PIL import Image

def remove_white_bg(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    datas = img.getdata()

    new_data = []
    for item in datas:
        # change all white (also shades of whites)
        # to transparent
        if item[0] > 220 and item[1] > 220 and item[2] > 220:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)

    img.putdata(new_data)
    
    # Resize to a reasonable dimension like 100x100 if it's too big, maintaining aspect ratio
    # Just standard thumbnailing so we don't overload flutter
    img.thumbnail((256, 256), Image.Resampling.LANCZOS)
    
    img.save(output_path, "PNG")

if __name__ == "__main__":
    input_file = r"C:\Users\SALVIYA\.gemini\antigravity-ide\brain\aeb3eac3-2e67-4bba-a619-348725959143\drosophila_adult_1790508194754.png"
    output_file = r"C:\Users\SALVIYA\Documents\Brain Fly\assets\flies\drosophila_adult.png"
    remove_white_bg(input_file, output_file)
    print("Done")
