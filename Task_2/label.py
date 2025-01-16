import fitz  # PyMuPDF for PDF processing
from PIL import Image, ImageDraw
import cv2
import numpy as np

# Function to extract label from the PDF file
def extract_label_from_pdf(pdf_path):
    doc = fitz.open(pdf_path)
    for page_num in range(len(doc)):
        page = doc.load_page(page_num)
        mat = fitz.Matrix(2, 2)  # Increase resolution by scaling
        pix = page.get_pixmap(matrix=mat)  # Render page to an image with higher resolution
        label_image = Image.frombytes("RGB", (pix.width, pix.height), pix.samples)
        label_image.show()  # Debug: Display the extracted label image
        return label_image

# Function to detect blank label area in the image
def detect_blank_area(image_path):
    image = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    _, thresh = cv2.threshold(image, 240, 255, cv2.THRESH_BINARY)
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    # Find the largest contour assuming it's the blank label area
    largest_contour = max(contours, key=cv2.contourArea)
    x, y, w, h = cv2.boundingRect(largest_contour)
    return x, y, w, h

# Function to place the label on the detected blank area
def place_label_on_image(input_image_path, label_image, output_image_path):
    input_image = Image.open(input_image_path).convert("RGB")
    x, y, w, h = detect_blank_area(input_image_path)

    # Resize label to fit the blank area
    label_resized = label_image.resize((w, h))
    input_image.paste(label_resized, (x, y))

    # Save the output image
    input_image.save(output_image_path)

if __name__ == "__main__":
    pdf_path = "V:\Web_Development\Gristip_Internship\Task_2\label.pdf"
    input_images = ["V:\Web_Development\Gristip_Internship\Task_2\input_length.png", "V:\Web_Development\Gristip_Internship\Task_2\input_breadth.png"]
    output_images = ["output_length.jpg", "output_breadth.jpg"]

    # Extract label from PDF
    label_image = extract_label_from_pdf(pdf_path)

    # Place the label on each input image
    for input_image_path, output_image_path in zip(input_images, output_images):
        place_label_on_image(input_image_path, label_image, output_image_path)

    print("Label placement completed. Output images saved.")