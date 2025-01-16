import PyPDF2
import fitz
from PIL import Image, ImageDraw
from io import BytesIO
import os

# Function to resize PDFs dynamically
def resize_pdf():
    # Prompt user for input files
    input_files = input("Enter the paths of the PDF files separated by commas: ").split(',')
    input_files = [file.strip() for file in input_files]

    # Validate file paths
    valid_files = []
    # Iterate over the input files to check if they are valid PDF files
    for file_path in input_files:
        # Check if the file exists and has a .pdf extension
        if os.path.isfile(file_path) and file_path.lower().endswith('.pdf'):
            valid_files.append(file_path)
        else:
            print(f"Invalid file skipped: {file_path}")

    if not valid_files:
        print("No valid PDF files provided. Exiting.")
        return

    # Prompt for output file
    output_file = input("Enter the output file name (e.g., compressed_output.pdf): ").strip()
    if not output_file.lower().endswith('.pdf'):
        output_file += ".pdf" # Append .pdf extension if not provided
    
    # Initialize PDF writer
    pdf_writer = PyPDF2.PdfWriter()

    # List to store resized images from PDFs
    images = []
    for file_path in valid_files:
        try:
            pdf_document = fitz.open(file_path) # Open PDF file using PyMuPDF(fitz)
            for page_num in range(pdf_document.page_count):
                # Load each page of the PDF
                page = pdf_document.load_page(page_num)

                # Resize to 1/4th of the original size
                matrix = fitz.Matrix(0.5, 0.5) #  Resize the page to 1/4th of the original size
                pix = page.get_pixmap(matrix=matrix) # Get the pixmap of the resized page
                img = Image.open(BytesIO(pix.tobytes())) # Open the pixmap as an image
                images.append(img)
        except Exception as e:
            print(f"Error processing {file_path}: {e}")

    if not images:
        print("No valid pages to process. Exiting.")
        return
    # Combine resized pages into output PDF
    try:
        # Create a new PDF file with the resized images in a 2x2 grid layout
        page_width, page_height = images[0].size # Use the size of the first image as the page size for the output PDF
        images_per_page = 4 # 2x2 grid
        border_width = 1  # Increased border width for better distinction
        margin = 10  # Margin between images

        # Split images into batches based on the number of images per page
        for i in range(0, len(images), images_per_page):
            # Create a new page for each batch of images and combine them into a single PDF
            batch_images = images[i:i + images_per_page]
            # Determine the layout of the images on the page based on the number of images in the batch
            # Determine the number of rows and columns based on the number of images in the batch
            # Adjust the layout based on the number of images in the batch            

            rows, cols = 2, 2
            
            # Calculate the width and height of each quadrant based on the number of rows and columns
            quadrant_width = (page_width - (cols + 1) * margin) // cols
            quadrant_height = (page_height - (rows + 1) * margin) // rows
            ## Create a new image to combine the resized images
            combined_img = Image.new('RGB', (page_width, page_height), color='white')
            
            # Define the positions for each quadrant based on the layout of the images on the page
            positions = [
                (margin, margin), # Top-left
                (quadrant_width + 2 * margin, margin), # Top-right
                (margin, quadrant_height + 2 * margin), # Bottom-left
                (quadrant_width + 2 * margin, quadrant_height + 2 * margin) # Bottom-right
            ]
            # Resize and paste each image into the corresponding quadrant on the page
            for j, img in enumerate(batch_images):
                img_resized = img.resize((quadrant_width - 2 * border_width, quadrant_height - 2 * border_width))
                # Add a border around the resized image
                bordered_img = Image.new('RGB', (img_resized.width + 2 * border_width, img_resized.height + 2 * border_width), color='black')
                # Paste the resized image onto the bordered image
                bordered_img.paste(img_resized, (border_width, border_width))

                # Calculate the position to paste the bordered image on the combined image
                paste_position = (positions[j][0] + (quadrant_width - bordered_img.width) // 2,
                                  positions[j][1] + (quadrant_height - bordered_img.height) // 2)
                combined_img.paste(bordered_img, paste_position)

            # Save the combined image as a PDF buffer(temporary storage location) and add it to the output PDF
            img_pdf_buffer = BytesIO()
            # Save the combined image as a PDF buffer
            combined_img.save(img_pdf_buffer, format="PDF")
            # Reset the buffer position to the beginning
            img_pdf_buffer.seek(0)

            # Add the combined image to the output PDF using PyPDF2
            pdf_reader = PyPDF2.PdfReader(img_pdf_buffer)
            pdf_writer.add_page(pdf_reader.pages[0])

        # Save the output PDF file
        with open(output_file, "wb") as output_pdf:
            pdf_writer.write(output_pdf)

        print(f"Compressed PDF saved as {output_file}")

    except Exception as e:
        print(f"Error creating output PDF: {e}")

if __name__ == "__main__":
    resize_pdf()
