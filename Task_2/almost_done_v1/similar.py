from PIL import Image, ImageChops

# Function to add the extracted label to the white area of the new image
def add_label_to_image(background_image_path, label_image_path, position, white_area_size):
    # Open the background image (courier with white area)
    background = Image.open(background_image_path)
    
    # Open the extracted label image
    label = Image.open(label_image_path)
    
    # Ensure the label has an alpha channel for transparency (convert to RGBA if not already)
    if label.mode != 'RGBA':
        label = label.convert('RGBA')
    
    # Resize the label to fit into the white space using high-quality resampling
    label = label.resize(white_area_size, Image.LANCZOS)  # Resize to the size of the white area with high-quality filter
    
    # Get the position where the label will be placed
    x, y = position

    # Create a mask from the label's alpha channel (transparency)
    mask = label.split()[3]  # This gets the alpha channel

    # Paste the label image onto the background image at the specified position using the mask
    background.paste(label, (x, y), mask)  # Use the alpha channel as mask for transparency

    # Save the final image with the label
    background.save("final_image_with_label.png")
    print("Label added and saved as 'final_image_with_label.png'.")

# Function to find the white area in the image and return its position and size
def find_white_area(image_path, threshold=200):
    image = Image.open(image_path)
    image = image.convert('L')  # Convert to grayscale
    width, height = image.size

    # Define the region to search (expanded to cover more area)
    region = (width // 8, height // 8, 7 * width // 8, 7 * height // 8)
    region_width = region[2] - region[0]
    region_height = region[3] - region[1]

    white_area = None
    for y in range(region[1], region[3]):
        for x in range(region[0], region[2]):
            if image.getpixel((x, y)) >= threshold:  # Check for white pixel based on threshold
                if white_area is None:
                    white_area = (x, y, x, y)
                else:
                    white_area = (min(white_area[0], x), min(white_area[1], y), max(white_area[2], x), max(white_area[3], y))
    
    if white_area is None:
        return None, None
    else:
        position = (white_area[0], white_area[1])
        size = (white_area[2] - white_area[0] + 1, white_area[3] - white_area[1] + 1)
        print(f"White area position: {position}, size: {size}")  # Print the position and size of the white area
        return position, size

# Example usage
background_image_path = "V:/Web_Development/Gristip_Internship/Task_2/input_length.png"  # Path to your courier image
label_image_path = "V:/Web_Development/Gristip_Internship/Task_2/only_label/extracted_label_high_quality.png"   # Path to the extracted label image

# Find the position and size of the white area dynamically
position, white_area_size = find_white_area(background_image_path)
if position is None:
    print("No white area found in the image.")
else:
    add_label_to_image(background_image_path, label_image_path, position, white_area_size)
