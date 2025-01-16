import fitz  # PyMuPDF
from PIL import Image, ImageDraw, ImageFont
import zipfile
import io
import os

# Function to extract text from PDF
def extract_pdf_content(pdf_file_path):
    doc = fitz.open(pdf_file_path)
    content = ""
    for page_num in range(doc.page_count):
        page = doc.load_page(page_num)
        content += page.get_text("text")
    return content

# Function to place label on image (only for length and breadth areas, excluding height image)
def place_label_on_image(image_path, label_content, label_position, label_size, height_image=False):
    if height_image:
        # If it's the "height" image, return None
        return None
    
    # Open the image
    img = Image.open(image_path)
    
    # Create a drawing object
    draw = ImageDraw.Draw(img)
    
    # Define the font for the label text
    try:
        font = ImageFont.truetype("arial.ttf", size=12)
    except IOError:
        font = ImageFont.load_default()
    
    # Position and size of the label (customizable)
    label_width, label_height = label_size
    label_x, label_y = label_position
    
    # Draw label text onto the image
    draw.text((label_x, label_y), label_content, font=font, fill="black")
    
    # Save the updated image
    return img

# Function to create a ZIP file containing the updated images
def create_zip(images, zip_file_path):
    with zipfile.ZipFile(zip_file_path, "w") as zipf:
        for idx, img in enumerate(images):
            if img is not None:
                img_byte_arr = io.BytesIO()
                img.save(img_byte_arr, format="PNG")
                zipf.writestr(f"image_{idx+1}.png", img_byte_arr.getvalue())

# Main function to process the input and generate the output
def automate_labeling(pdf_file_path, image_paths, label_position, label_size, height_image_index, output_zip_path):
    # Extract content from PDF
    label_content = extract_pdf_content(pdf_file_path)
    
    updated_images = []
    
    for idx, image_path in enumerate(image_paths):
        # Skip the labeling process for the height image
        is_height_image = (idx == height_image_index)
        updated_img = place_label_on_image(image_path, label_content, label_position, label_size, height_image=is_height_image)
        if not is_height_image:
            updated_images.append(updated_img)
    
    # Create a ZIP file with all the updated images
    create_zip(updated_images, output_zip_path)

# Example usage
pdf_file_path = "V:\Web_Development\Gristip_Internship\Task_2\label.pdf"
image_paths = ["V:\Web_Development\Gristip_Internship\Task_2\input_breadth.png", "V:\Web_Development\Gristip_Internship\Task_2\input_length.png", "V:\Web_Development\Gristip_Internship\Task_2\input_height.png"]
label_position = (100, 100)  # (x, y) position for the label on the image (length, breadth)
label_size = (200, 50)  # (width, height) of the label
height_image_index = 2  # Specify the index (0-based) of the height image (e.g., 2 for the third image)
output_zip_path = "updated_images.zip"

automate_labeling(pdf_file_path, image_paths, label_position, label_size, height_image_index, output_zip_path)

