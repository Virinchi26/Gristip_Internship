import os
import fitz
import PyPDF2
from PIL import Image
from io import BytesIO
from flask import Flask, request, send_file, render_template

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
OUTPUT_FOLDER = 'output'
ALLOWED_EXTENSIONS = {'pdf'}

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['OUTPUT_FOLDER'] = OUTPUT_FOLDER

# Create upload and output directories if they don't exist
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# Helper function to check allowed extensions
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# Resize PDF and combine logic (adapted from your existing function)
def resize_pdf(input_files, output_file):
    pdf_writer = PyPDF2.PdfWriter()
    images = []

    # Process each file
    for file_path in input_files:
        try:
            pdf_document = fitz.open(file_path)
            for page_num in range(pdf_document.page_count):
                page = pdf_document.load_page(page_num)
                matrix = fitz.Matrix(0.5, 0.5)
                pix = page.get_pixmap(matrix=matrix)
                img = Image.open(BytesIO(pix.tobytes()))
                images.append(img)
        except Exception as e:
            print(f"Error processing {file_path}: {e}")

    if not images:
        raise ValueError("No valid pages to process.")

    try:
        page_width, page_height = images[0].size
        images_per_page = 4
        border_width = 1
        margin = 10

        for i in range(0, len(images), images_per_page):
            batch_images = images[i:i + images_per_page]

            if len(batch_images) == 1:
                rows, cols = 1, 1
            elif len(batch_images) == 2:
                rows, cols = 1, 2
            elif len(batch_images) == 3:
                rows, cols = 2, 2
            else:
                rows, cols = 2, 2

            quadrant_width = (page_width - (cols + 1) * margin) // cols
            quadrant_height = (page_height - (rows + 1) * margin) // rows
            combined_img = Image.new('RGB', (page_width, page_height), color='white')

            positions = [
                (margin, margin),
                (quadrant_width + 2 * margin, margin),
                (margin, quadrant_height + 2 * margin),
                (quadrant_width + 2 * margin, quadrant_height + 2 * margin)
            ]

            for j, img in enumerate(batch_images):
                img_resized = img.resize((quadrant_width - 2 * border_width, quadrant_height - 2 * border_width))
                bordered_img = Image.new('RGB', (img_resized.width + 2 * border_width, img_resized.height + 2 * border_width), color='black')
                bordered_img.paste(img_resized, (border_width, border_width))
                paste_position = (positions[j][0] + (quadrant_width - bordered_img.width) // 2,
                                  positions[j][1] + (quadrant_height - bordered_img.height) // 2)
                combined_img.paste(bordered_img, paste_position)

            img_pdf_buffer = BytesIO()
            combined_img.save(img_pdf_buffer, format="PDF")
            img_pdf_buffer.seek(0)

            pdf_reader = PyPDF2.PdfReader(img_pdf_buffer)
            pdf_writer.add_page(pdf_reader.pages[0])

        with open(output_file, "wb") as output_pdf:
            pdf_writer.write(output_pdf)

    except Exception as e:
        raise ValueError(f"Error creating output PDF: {e}")

# Route for the home page with the form
@app.route('/')
def index():
    return render_template('index.html')

# Route to handle file upload and PDF generation
@app.route('/upload', methods=['POST'])
def upload_file():
    if 'files[]' not in request.files:
        return "No file part", 400

    files = request.files.getlist('files[]')
    if len(files) == 0:
        return "No files selected", 400

    num_files = len(files)
    input_files = []

    # Save the files
    for file in files:
        if file and allowed_file(file.filename):
            filename = os.path.join(app.config['UPLOAD_FOLDER'], file.filename)
            file.save(filename)
            input_files.append(filename)

    output_file = os.path.join(app.config['OUTPUT_FOLDER'], f"compressed_output_{num_files}.pdf")

    try:
        resize_pdf(input_files, output_file)
        # Serve the output file
        return send_file(output_file, as_attachment=True)
    except Exception as e:
        return f"Error: {e}", 500

if __name__ == "__main__":
    app.run(debug=True)
