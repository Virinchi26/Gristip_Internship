import fitz  # PyMuPDF
from PIL import Image, ImageDraw, ImageFont
import zipfile
import io
import re

# Function to extract label text and dimensions (length, breadth, height) from the PDF
def extract_pdf_content(pdf_file_path):
    doc = fitz.open(pdf_file_path)
    content = ""
    label_dimensions = {}

    # Extract content from each page
    for page_num in range(doc.page_count):
        page = doc.load_page(page_num)
        text = page.get_text("text")
        content += text
        
        # Print the extracted text to debug
        print(f"Extracted text from page {page_num+1}:\n{text}\n")

        # Extract dimensions in the format: 15.00*10.00*10.00 (cm)
        dimension_pattern = r"(\d+\.?\d*)\s*\*\s*(\d+\.?\d*)\s*\*\s*(\d+\.?\d*)\s*\(cm\)"
        match = re.search(dimension_pattern, text)
        if match:
            label_dimensions = {
                "length": float(match.group(1)),
                "breadth": float(match.group(2)),
                "height": float(match.group(3))
            }
            print(f"Extracted dimensions: {label_dimensions}")
    
    # If dimensions are not found, print a warning
    if not label_dimensions:
        print("Warning: Label dimensions not found in the PDF!")

    return content, label_dimensions

# Function to find the white blank space in the image and place the label in that space
def place_label_on_image(image_path, label_content, label_position, label_size, label_dimensions):
    # Check if label_dimensions contains the expected keys
    if "length" not in label_dimensions or "breadth" not in label_dimensions:
        print("Error: Missing 'length' or 'breadth' in label_dimensions!")
        return None

    # Open image
    img = Image.open(image_path)
    
    # Create a drawing object
    draw = ImageDraw.Draw(img)
    
    # Define the font for the label text
    try:
        font = ImageFont.truetype("arial.ttf", size=12)
    except IOError:
        font = ImageFont.load_default()

    # Extract label dimensions (length, breadth, height)
    label_length = label_dimensions["length"]
    label_breadth = label_dimensions["breadth"]

    # Find the blank space: We'll assume it's in the center of the image
    image_width, image_height = img.size

    # Identify the blank space: For simplicity, assume the blank space is centered
    blank_space_x = (image_width - label_length) // 2
    blank_space_y = (image_height - label_breadth) // 2

    # Position the label content within the blank space
    label_x = blank_space_x
    label_y = blank_space_y

    # Draw label text onto the image within the blank space
    draw.text((label_x, label_y), label_content, font=font, fill="black")

    # Save the updated image
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
    # Extract content and dimensions from PDF
    label_content, label_dimensions = extract_pdf_content(pdf_file_path)

    # Check if the label dimensions are valid
    if not label_dimensions:
        print("Error: Could not extract valid label dimensions from the PDF!")
        return

    updated_images = []
    
    for image_path in image_paths:
        # Skip the height image
        if "height" in image_path:
            continue
        
        # Place the label on the image within the identified blank space
        updated_img = place_label_on_image(image_path, label_content, (0, 0), (label_dimensions["length"], label_dimensions["breadth"]), label_dimensions)
        if updated_img is not None:
            updated_images.append(updated_img)
    
    # Create a ZIP file with all the updated images
    create_zip(updated_images, output_zip_path)

# Example usage
pdf_file_path = "V:/Web_Development/Gristip_Internship/Task_2/label.pdf"
image_paths = ["V:/Web_Development/Gristip_Internship/Task_2/input_breadth.png", "V:/Web_Development/Gristip_Internship/Task_2/input_length.png", "V:/Web_Development/Gristip_Internship/Task_2/input_height.png"]
output_zip_path = "updated_images.zip"

automate_labeling(pdf_file_path, image_paths, output_zip_path)