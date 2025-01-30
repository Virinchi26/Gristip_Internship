

import cv2
import numpy as np
import fitz  # PyMuPDF for extracting PDF content
from PIL import Image

# Load the courier image
courier_img_path = "V:\Web_Development\Gristip_Internship\Task_2\input_length.png"
courier_img = cv2.imread(courier_img_path)

# Convert to grayscale and threshold to detect the white blank space
gray = cv2.cvtColor(courier_img, cv2.COLOR_BGR2GRAY)
_, thresh = cv2.threshold(gray, 240, 255, cv2.THRESH_BINARY)

# Find contours to detect white spaces
contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

# Identify the contour closest to the center of the image
img_center_x, img_center_y = courier_img.shape[1] // 2, courier_img.shape[0] // 2
best_contour = None
min_distance = float("inf")

for contour in contours:
    x, y, w, h = cv2.boundingRect(contour)
    center_x, center_y = x + w // 2, y + h // 2
    distance = ((center_x - img_center_x) ** 2 + (center_y - img_center_y) ** 2) ** 0.5
    
    # Prefer contours closer to the center and reasonably sized
    if distance < min_distance and w > 50 and h > 50:  # Ensuring a reasonable size
        best_contour = (x, y, w, h)
        min_distance = distance

if best_contour:
    x, y, w, h = best_contour  # Coordinates of detected central white space

# Extract the label from the first quadrant of the PDF
pdf_path = "V:\Web_Development\Gristip_Internship\Task_2\label.pdf"
doc = fitz.open(pdf_path)
page = doc[0]  # First page

# Get the first quadrant of the page
pix = page.get_pixmap()
label_img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
label_img = label_img.crop((0, 0, pix.width // 2, pix.height // 2))  # First quadrant

# Convert label to OpenCV format with transparency
label_img = label_img.convert("RGBA")
label_np = np.array(label_img)
label_np = cv2.cvtColor(label_np, cv2.COLOR_RGBA2BGRA)

# Resize the label to fit the detected white space
label_resized = cv2.resize(label_np, (w, h))

# Rotate the label to match the orientation of the detected space
angle = 0  # Adjust as needed, can calculate based on bounding box if rotated
M = cv2.getRotationMatrix2D((w//2, h//2), angle, 1)
label_rotated = cv2.warpAffine(label_resized, M, (w, h))

# Create mask for transparency and overlay it properly
alpha_mask = label_rotated[:, :, 3] / 255.0
for c in range(3):  # Apply alpha blending
    courier_img[y:y+h, x:x+w, c] = (
        alpha_mask * label_rotated[:, :, c] + (1 - alpha_mask) * courier_img[y:y+h, x:x+w, c]
    )

# Save the final image
output_path = "final_output.png"
cv2.imwrite(output_path, courier_img)

print(f"Processed image saved at: {output_path}")
