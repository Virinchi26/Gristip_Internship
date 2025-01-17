import fitz  # PyMuPDF
from PIL import Image, ImageOps
import io

# Function to extract and save the label as an image with high quality
def extract_label_from_pdf(pdf_path, page_num=0, quadrant=(0, 0, 300, 300), zoom_factor=3):
    # Open the PDF
    doc = fitz.open(pdf_path)

    # Extract the page (you can specify the page number)
    page = doc.load_page(page_num)  # Page numbers are 0-indexed
    
    # Define the rectangular area (first quadrant) to extract (x0, y0, x1, y1)
    rect = fitz.Rect(quadrant)
    
    # Create a transformation matrix to zoom in for higher quality
    matrix = fitz.Matrix(zoom_factor, zoom_factor)  # Increase zoom_factor for better quality
    
    # Crop the area from the page and render it with the matrix for higher DPI
    pix = page.get_pixmap(matrix=matrix, clip=rect)
    
    # Convert the pixmap to a PIL Image
    img = Image.open(io.BytesIO(pix.tobytes()))
    
    # Optionally trim the border using PIL
    img = trim_border(img)
    
    # Save the image
    img.save("extracted_label_high_quality.png")
    print("Label extracted and saved as 'extracted_label_high_quality.png'.")

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

# Example usage
pdf_path = "V:\Web_Development\Gristip_Internship\Task_2\label.pdf"
extract_label_from_pdf(pdf_path, page_num=0, quadrant=(0, 0, 300, 300), zoom_factor=3)  # Adjust zoom_factor for better quality
