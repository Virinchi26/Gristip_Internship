import PyPDF2
import fitz  # PyMuPDF
from PIL import Image
from io import BytesIO

def resize_pdf(input_files, output_file):
    # Create a new PDF writer object to store the resulting PDF
    pdf_writer = PyPDF2.PdfWriter()

    # List to store the resized images (one image per PDF page)
    images = []

    # Process each input file
    for file_path in input_files:
        # Open the PDF file using PyMuPDF (fitz)
        pdf_document = fitz.open(file_path)

        for page_num in range(pdf_document.page_count):
            page = pdf_document.load_page(page_num)
            
            # Get the original page size
            original_width = page.rect.width
            original_height = page.rect.height
            
            # Resize the page to 1/2 of its original size (so it fits in 1/4th of the final page)
            matrix = fitz.Matrix(0.5, 0.5)  # 50% scaling -> 1/4th the area of the original
            
            # Render the page as an image with the reduced size
            pix = page.get_pixmap(matrix=matrix)
            
            # Convert pixmap (image) to a PIL Image
            img = Image.open(BytesIO(pix.tobytes()))
            
            images.append(img)

    # Get the number of PDFs and calculate grid layout
    num_images = len(images)
    
    # Determine the grid layout (1x1, 1x2, 2x2, etc.)
    if num_images == 1:
        rows, cols = 1, 1
    elif num_images == 2:
        rows, cols = 1, 2  # 2 PDFs: horizontal layout (1 row, 2 columns)
    elif num_images == 3:
        rows, cols = 2, 2  # 3 PDFs: 2x2 grid, 1 empty quadrant
    else:
        rows, cols = 2, 2  # 4 PDFs: 2x2 grid (fully filled)

    # Assuming we want to arrange the images to fit into an 8.5 x 11 page (letter size)
    page_width = 612  # 8.5 inches * 72 pixels/inch
    page_height = 792  # 11 inches * 72 pixels/inch

    # Calculate size of each image based on grid layout
    quadrant_width = page_width // cols
    quadrant_height = page_height // rows

    # Create a blank white canvas for the final page
    combined_img = Image.new('RGB', (page_width, page_height), color='white')

    # Place each image in its respective quadrant
    positions = [
        (0, 0),  # top-left
        (quadrant_width, 0),  # top-right
        (0, quadrant_height),  # bottom-left
        (quadrant_width, quadrant_height)  # bottom-right
    ]
    
    # Only place the images that exist, leave empty spaces for the rest
    for i, img in enumerate(images):  
        img_resized = img.resize((quadrant_width, quadrant_height))
        combined_img.paste(img_resized, positions[i])

    # Convert the combined image into a PDF
    img_pdf_buffer = BytesIO()
    combined_img.save(img_pdf_buffer, format="PDF")
    img_pdf_buffer.seek(0)  # Go to the start of the buffer
    
    # Append the combined image PDF as a new page to the result PDF
    pdf_reader = PyPDF2.PdfReader(img_pdf_buffer)
    pdf_writer.add_page(pdf_reader.pages[0])
    
    # Write the output PDF with one page containing all the images
    with open(output_file, "wb") as output_pdf:
        pdf_writer.write(output_pdf)
    print(f"Compressed PDF saved as {output_file}")



# Example usage
input_files = ["input_1.pdf","input_2.pdf", "input_3.pdf", "input_4.pdf"]  # List of input PDF file paths
output_file = "compressed_output.pdf"       # Output compressed PDF file path

resize_pdf(input_files, output_file)
