import fitz  # PyMuPDF
from PIL import Image, ImageDraw, ImageFont
import zipfile
import io
import re

# Function to extract the label as an image from the PDF
def extract_label_as_image(pdf_file_path, label_area):
    # Open the PDF document
    doc = fitz.open(pdf_file_path)

    # Render the first page as an image
    page = doc.load_page(0)
    pix = page.get_pixmap()

    # Convert to PIL Image
    img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)

    # Crop the image to the label area
    # label_area is expected to be in the format (left, top, right, bottom)
    label_image = img.crop(label_area)

    return label_image

# Function to find the white blank space in the image and place the label in that space
def place_label_on_image(image_path, label_image, label_dimensions):
    # Open the image
    img = Image.open(image_path)

    # Create a drawing object
    draw = ImageDraw.Draw(img)

    # Define the label's position and size in the target image (centered)
    image_width, image_height = img.size
    label_width, label_height = label_image.size

    # Find the blank space: Assume it's centered
    blank_space_x = (image_width - label_width) // 2
    blank_space_y = (image_height - label_height) // 2

    # Position the label content within the blank space
    label_x = blank_space_x
    label_y = blank_space_y

    # Paste the label image onto the target image
    img.paste(label_image, (label_x, label_y))

    return img

# Function to create a ZIP file containing the updated images
def create_zip(images, zip_file_path):
    with zipfile.ZipFile(zip_file_path, "w") as zipf:
        for idx, img in enumerate(images):
            img_byte_arr = io.BytesIO()
            img.save(img_byte_arr, format="PNG")
            zipf.writestr(f"image_{idx+1}.png", img_byte_arr.getvalue())

# Main function to process the input and generate the output
def automate_labeling(pdf_file_path, image_paths, output_zip_path):
    # Extract the label area as an image from the PDF
    # Let's assume the label area is at a fixed position; you'll need to adjust this if it's dynamic
    label_area = (100, 100, 400, 200)  # (left, top, right, bottom) in pixels (adjust as needed)
    label_image = extract_label_as_image(pdf_file_path, label_area)

    updated_images = []
    
    for image_path in image_paths:
        # Skip the height image (if needed)
        if "height" in image_path:
            continue
        
        # Place the label image on the target image
        updated_img = place_label_on_image(image_path, label_image, label_dimensions={})
        if updated_img is not None:
            updated_images.append(updated_img)
    
    # Create a ZIP file with all the updated images
    create_zip(updated_images, output_zip_path)

# Example usage
pdf_file_path = "V:/Web_Development/Gristip_Internship/Task_2/label.pdf"
image_paths = ["V:/Web_Development/Gristip_Internship/Task_2/input_breadth.png", "V:/Web_Development/Gristip_Internship/Task_2/input_length.png", "V:/Web_Development/Gristip_Internship/Task_2/input_height.png"]
output_zip_path = "updated_images_image.zip"

automate_labeling(pdf_file_path, image_paths, output_zip_path)
