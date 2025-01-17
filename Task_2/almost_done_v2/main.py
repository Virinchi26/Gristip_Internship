from PIL import Image

# Function to add the extracted label to the white area of the new image
def add_label_to_image(background_image_path, label_image_path, position, white_area_size, scale_factor=1.7):
    # Open the background image (courier with white area)
    background = Image.open(background_image_path)
    
    # Open the extracted label image
    label = Image.open(label_image_path)
    
    # Ensure the label has an alpha channel for transparency (convert to RGBA if not already)
    if label.mode != 'RGBA':
        label = label.convert('RGBA')
    
    # Increase the size of the white area by the scale factor
    new_white_area_size = (int(white_area_size[0] * scale_factor), int(white_area_size[1] * scale_factor))
    
    # Resize the label to fit into the white space using high-quality resampling
    label = label.resize(new_white_area_size, Image.LANCZOS)  # Resize to the size of the white area with high-quality filter
    
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
def find_white_area(image_path, threshold=200, margin=0.4):
    """
    Find the white area in the central region of the image based on the pixel color and given threshold.
    The search area is dynamic and is defined as a margin around the center of the image.
    This function will focus on the blank white area in the middle of the image.
    """
    image = Image.open(image_path)
    image = image.convert('L')  # Convert to grayscale
    width, height = image.size

    # Calculate the central region to focus on (with some margin)
    center_x, center_y = width // 2, height // 2
    search_width = int(width * margin)
    search_height = int(height * margin)

    left = max(0, center_x - search_width // 2)
    top = max(0, center_y - search_height // 2)
    right = min(width, center_x + search_width // 2)
    bottom = min(height, center_y + search_height // 2)

    white_area = None

    # Iterate through the central search area to find the white area
    for y in range(top, bottom):
        for x in range(left, right):
            if image.getpixel((x, y)) >= threshold:  # Check for white pixel based on threshold
                if white_area is None:
                    white_area = (x, y, x, y)  # Initialize the bounding box
                else:
                    # Expand the bounding box to encompass the new white pixel
                    white_area = (min(white_area[0], x), min(white_area[1], y), max(white_area[2], x), max(white_area[3], y))
    
    # If we found a white area, return its bounding box and position
    if white_area is None:
        return None, None
    else:
        # After finding the central area, we expand the box further to capture more of the blank white space
        expanded_white_area = expand_white_area(image, white_area, threshold)
        position = (expanded_white_area[0], expanded_white_area[1])
        size = (expanded_white_area[2] - expanded_white_area[0] + 1, expanded_white_area[3] - expanded_white_area[1] + 1)
        return position, size

# Function to expand the white area to capture more blank space around it
def expand_white_area(image, white_area, threshold=200):
    """
    Expands the bounding box around the detected white area to capture more blank space.
    """
    left, top, right, bottom = white_area
    width, height = image.size

    # Expand the bounding box by checking surrounding areas for white pixels
    for y in range(top, bottom + 1):
        for x in range(left, right + 1):
            # Check above and below the bounding box for white pixels
            if y - 1 >= 0 and image.getpixel((x, y - 1)) >= threshold:
                top = min(top, y - 1)
            if y + 1 < height and image.getpixel((x, y + 1)) >= threshold:
                bottom = max(bottom, y + 1)

            # Check left and right of the bounding box for white pixels
            if x - 1 >= 0 and image.getpixel((x - 1, y)) >= threshold:
                left = min(left, x - 1)
            if x + 1 < width and image.getpixel((x + 1, y)) >= threshold:
                right = max(right, x + 1)

    return left, top, right, bottom

# Example usage
background_image_path = "V:/Web_Development/Gristip_Internship/Task_2/input_length.png"  # Path to your courier image
label_image_path = "V:/Web_Development/Gristip_Internship/Task_2/only_label/extracted_label_high_quality.png"   # Path to the extracted label image

# Find the position and size of the white area dynamically (focused on the central region)
position, white_area_size = find_white_area(background_image_path, threshold=200, margin=0.4)  # Adjust margin as needed
if position is None:
    print("No white area found in the image.")
else:
    # Add label with scaled size according to the detected white area size
    add_label_to_image(background_image_path, label_image_path, position, white_area_size, scale_factor=1.7)  # Adjust scale_factor as needed
