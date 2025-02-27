import fitz  # PyMuPDF
from PIL import Image, ImageOps
import io

# Function to extract and save the label as an image with high quality
def extract_label_from_pdf(pdf_path, page_num=0, quadrant=(0, 0, 300, 300), zoom_factor=4, background_color=(255, 255, 255)):
    # Open the PDF
    doc = fitz.open(pdf_path)

    # Extract the page (you can specify the page number)
    page = doc.load_page(page_num)  # Page numbers are 0-indexed
    
    # Define the rectangular area (first quadrant) to extract (x0, y0, x1, y1)
    rect = fitz.Rect(quadrant)
    
    # Create a transformation matrix to zoom in for higher quality (higher zoom_factor gives better resolution)
    matrix = fitz.Matrix(zoom_factor, zoom_factor)  # Increasing zoom_factor for better resolution
    
    # Crop the area from the page and render it with the matrix for higher DPI
    pix = page.get_pixmap(matrix=matrix, clip=rect, dpi=300)  # Ensure high DPI
    
    # Convert the pixmap to a PIL Image
    img = Image.open(io.BytesIO(pix.tobytes()))
    
    # Optionally trim the border using PIL
    img = trim_border(img)
    
    # Remove background by converting the image to RGBA and making white pixels transparent
    img = remove_background(img, background_color)
    
    # Save the image with transparent background in highest quality (PNG format)
    img.save("extracted_label_no_background.png", "PNG", quality=100, optimize=True)
    print("Label extracted with no background and saved as 'extracted_label_no_background.png'.")

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

# Function to remove the background of the image (assuming background is a specific color)
def remove_background(img, background_color):
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

# Example usage
pdf_path = "V:/Web_Development/Gristip_Internship/Task_2/label.pdf"
extract_label_from_pdf(pdf_path, page_num=0, quadrant=(0, 0, 300, 300), zoom_factor=4)  # Higher zoom_factor for better quality
