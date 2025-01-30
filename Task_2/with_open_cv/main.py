import fitz  # PyMuPDF
from PIL import Image
import cv2
import numpy as np

# Step 1: Extract only the label (first quadrant) from the PDF
def extract_label_from_pdf(pdf_path, output_image_path):
    # Open the PDF file
    pdf_document = fitz.open(pdf_path)
    
    # Load the first page
    page = pdf_document.load_page(0)
    
    # Get the dimensions of the page
    page_width = page.rect.width
    page_height = page.rect.height
    
    # Define the first quadrant (top-left corner)
    clip_rect = fitz.Rect(0, 0, page_width / 2, page_height / 2)
    
    # Get the pixmap for the first quadrant
    pix = page.get_pixmap(clip=clip_rect)
    
    # Save the extracted label as an image
    pix.save(output_image_path)

# Step 2: Convert the label to an image with transparency
def make_image_transparent(image_path, output_path):
    img = Image.open(image_path)
    img = img.convert("RGBA")
    
    # Make white pixels transparent
    datas = img.getdata()
    new_data = []
    for item in datas:
        # Change all white (or near-white) pixels to transparent
        if item[0] > 200 and item[1] > 200 and item[2] > 200:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
    
    img.putdata(new_data)
    img.save(output_path, "PNG")

# Step 3: Identify the white blank space in the courier and paste the label
def paste_label_on_courier(courier_image_path, label_image_path, output_path):
    # Load the courier image
    courier_img = cv2.imread(courier_image_path, cv2.IMREAD_UNCHANGED)
    
    # Load the label image with transparency
    label_img = cv2.imread(label_image_path, cv2.IMREAD_UNCHANGED)
    
    # Convert the courier image to grayscale to find white regions
    gray_courier = cv2.cvtColor(courier_img, cv2.COLOR_BGR2GRAY)
    
    # Threshold the image to find white regions (adjust threshold as needed)
    _, white_mask = cv2.threshold(gray_courier, 200, 255, cv2.THRESH_BINARY)
    
    # Find contours of the white regions
    contours, _ = cv2.findContours(white_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    # Find the largest white region (assuming it's the blank space)
    largest_contour = max(contours, key=cv2.contourArea)
    x, y, w, h = cv2.boundingRect(largest_contour)
    
    # Resize the label to fit the blank space
    label_resized = cv2.resize(label_img, (w, h))
    
    # Overlay the label onto the courier image
    for c in range(0, 3):
        courier_img[y:y+h, x:x+w, c] = label_resized[:, :, c] * (label_resized[:, :, 3] / 255.0) + courier_img[y:y+h, x:x+w, c] * (1.0 - label_resized[:, :, 3] / 255.0)
    
    # Save the final image
    cv2.imwrite(output_path, courier_img)

# Main function to execute the steps
def main():
    pdf_path = "V:\Web_Development\Gristip_Internship\Task_2\label.pdf"
    courier_image_path = "V:\Web_Development\Gristip_Internship\Task_2\input_length.png"
    label_image_path = "label_image.png"
    transparent_label_path = "transparent_label.png"
    output_image_path = "output_courier.png"
    
    # Step 1: Extract the label from the first quadrant of the PDF
    extract_label_from_pdf(pdf_path, label_image_path)
    
    # Step 2: Make the label image transparent
    make_image_transparent(label_image_path, transparent_label_path)
    
    # Step 3: Paste the label onto the white blank space in the courier image
    paste_label_on_courier(courier_image_path, transparent_label_path, output_image_path)

if __name__ == "__main__":
    main()