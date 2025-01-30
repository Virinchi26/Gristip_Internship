from PIL import Image, ImageOps
import fitz  # PyMuPDF
import io

# Function to extract and save the label as an image with high quality and transparent background
def extract_label_from_pdf(pdf_path, page_num=0, quadrant=(0, 0, 300, 300), zoom_factor=10, background_color=(255, 255, 255)):
    # Open the PDF
    doc = fitz.open(pdf_path)

    # Extract the page (you can specify the page number)
    page = doc.load_page(page_num)  # Page numbers are 0-indexed
    
    # Define the rectangular area (first quadrant) to extract (x0, y0, x1, y1)
    rect = fitz.Rect(quadrant)
    
    # Create a transformation matrix to zoom in for higher quality (higher zoom_factor gives better resolution)
    matrix = fitz.Matrix(zoom_factor, zoom_factor)  # Increasing zoom_factor for better resolution
    
    # Crop the area from the page and render it with the matrix for higher DPI
    pix = page.get_pixmap(matrix=matrix, clip=rect, dpi=600)  # Ensure high DPI
    
    # Convert the pixmap to a PIL Image
    img = Image.open(io.BytesIO(pix.tobytes()))
    
    # Optionally trim the border using PIL
    img = trim_border(img)
    
    # Convert to transparent PNG by making the background transparent
    img = make_background_transparent(img, background_color)
    
    return img

# Function to automatically trim borders from the image
def trim_border(img):
    # Convert image to grayscale to find borders
    grayscale_img = img.convert("L")
    
    # Use PIL's ImageOps to find the bounding box (non-white pixels)
    bbox = ImageOps.invert(grayscale_img).getbbox()
    
    # Crop the image to the bounding box (removes extra border)
    if bbox:
        return img.crop(bbox)
    else:
        return img

# Function to make the background transparent (converts white pixels to transparent)
def make_background_transparent(img, background_color):
    # Convert the image to RGBA (supporting transparency)
    img = img.convert("RGBA")
    
    # Create a new image where we will store the result
    data = img.getdata()

    new_data = []
    for item in data:
        # Change all pixels that match the background color to transparent
        if item[:3] == background_color:  # Compare RGB part
            new_data.append((255, 255, 255, 0))  # Transparent pixel
        else:
            new_data.append(item)  # Keep non-background pixels unchanged
    
    # Put the new data back into the image
    img.putdata(new_data)
    
    return img

# Function to add the extracted label to a fixed position in the courier (background) image
def place_label_on_courier(courier_path, label_img, position=(100, 100), size=(200, 100), rotate_angle=0):
    # Open the courier image (background where label will be placed)
    courier = Image.open(courier_path)

    # Resize label to fit the designated rectangular area (if necessary)
    label_img = label_img.resize(size, Image.LANCZOS)  # Resize the label using high-quality resampling
    
    # Optionally, rotate the label before pasting (if needed)
    if rotate_angle != 0:
        label_img = label_img.rotate(rotate_angle, expand=True)  # Rotate the image by the specified angle
    
    # Create a copy of the courier image to avoid modifying the original
    courier_copy = courier.copy()

    # Paste the label onto the courier image at the specified position
    # Ensure the alpha channel (transparency) is preserved
    # embedding the label on the courier image
    courier_copy.paste(label_img, position, label_img)

    # Save the final image
    courier_copy.save("courier_with_label_length.png", "PNG", quality=100, optimize=True)
    print("Label placed on courier image and saved as 'courier_with_label_length.png'.")

# Example usage without adding the border
pdf_path = "V:/Web_Development/Gristip_Internship/Task_2/label.pdf"
courier_path = "V:/Web_Development/Gristip_Internship/Task_2/input_length.png"  # Path to the courier image

# Extract the label (with transparent background)
label_img = extract_label_from_pdf(pdf_path, page_num=0, quadrant=(0, 0, 300, 300), zoom_factor=10)

# Place the label on the courier image at a fixed position, resize it, and rotate it if needed
place_label_on_courier(courier_path, label_img, position=(150, 170), size=(185, 250), rotate_angle=270)
