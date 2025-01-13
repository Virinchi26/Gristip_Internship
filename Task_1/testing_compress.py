import PyPDF2
import fitz
from PIL import Image
from io import BytesIO

def resize_pdf(input_files, output_file):
    pdf_writer = PyPDF2.PdfWriter()

    # List to store the resized images (one image per PDF page)
    images = []

    # To store the page dimensions from the first PDF to standardize the layout
    page_width = None
    page_height = None

    # Process each input file
    for file_path in input_files:
        # Open the PDF file using PyMuPDF (fitz)
        pdf_document = fitz.open(file_path)

        for page_num in range(pdf_document.page_count):
            page = pdf_document.load_page(page_num)
        
            # when the first page of a PDF is loaded (page = pdf_document.load_page(page_num)), the dimensions of the page are extracted dynamically using page.rect.width and page.rect.height
            if page_width is None or page_height is None:
                page_width = page.rect.width
                page_height = page.rect.height
            
            # Resize the page to 1/2 of its original size (so it fits in 1/4th of the final page)
            matrix = fitz.Matrix(0.5, 0.5)  # 50% scaling -> 1/4th the area of the original
            
            # Render the page as an image with the reduced size
            # each page is rendered as a pixmap (an image) and this creates an image at the resized resolution and the pixmap is then converted into a PIL Image object which allows further manipulation of the image.
            pix = page.get_pixmap(matrix=matrix)
            
            # Convert pixmap (image) to a PIL Image
            img = Image.open(BytesIO(pix.tobytes()))
            
            images.append(img)

    # Determine the number of pages needed based on the number of images (PDFs)
    num_images = len(images)
    images_per_page = 4  # Each page can hold 4 images (2x2 grid)

    # Process in batches of 4
    for i in range(0, num_images, images_per_page):
        # Determine how many images are in this batch (could be less than 4 for the last batch)
        batch_images = images[i:i + images_per_page]
        
        # Adjust grid layout based on the number of images in this batch
        if len(batch_images) == 1:
            rows, cols = 1, 1
        elif len(batch_images) == 2:
            rows, cols = 1, 2
        elif len(batch_images) == 3:
            rows, cols = 2, 2
        else:
            rows, cols = 2, 2  # Default grid is 2x2 (4 images per page)

        # Calculate size of each image based on grid layout
        quadrant_width = int(page_width // cols)
        quadrant_height = int(page_height // rows)

        # Create a blank white canvas for the final page (same size as input PDF page)
        combined_img = Image.new('RGB', (int(page_width), int(page_height)), color='white')

        # Place each image in its respective quadrant
        positions = [
            (0, 0),  # top-left
            (quadrant_width, 0),  # top-right
            (0, quadrant_height),  # bottom-left
            (quadrant_width, quadrant_height)  # bottom-right
        ]
        
        # Only place the images that exist in this batch, leave empty spaces for the rest
        for j, img in enumerate(batch_images):  
            img_resized = img.resize((int(quadrant_width), int(quadrant_height)))
            combined_img.paste(img_resized, positions[j])

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



input_files = ["input_1.pdf","input_2.pdf", "input_3.pdf", "input_4.pdf", "input_3.pdf", "input_1.pdf" ]  # List of input PDF file paths
output_file = "Final_compressed_output.pdf"       # Output compressed PDF file path

resize_pdf(input_files, output_file)
