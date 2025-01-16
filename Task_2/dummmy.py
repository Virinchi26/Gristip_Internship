import cv2
import numpy as np
import matplotlib.pyplot as plt

# Load the image
image_path = "V:\Web_Development\Gristip_Internship\Task_2\input_breadth.jpg"  # Replace with the path to your image
image = cv2.imread(image_path)

# Convert to grayscale
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

# Apply thresholding
_, thresh = cv2.threshold(gray, 50, 255, cv2.THRESH_BINARY_INV)

# Find contours
contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

# Draw the largest contour (assuming it's the black outline) on the original image
output_image = image.copy()
if contours:
    largest_contour = max(contours, key=cv2.contourArea)
    cv2.drawContours(output_image, [largest_contour], -1, (0, 255, 0), 2)

# Save or display the result
cv2.imwrite("detected_contour.png", output_image)  # Save the result
plt.figure(figsize=(10, 10))
plt.subplot(1, 2, 1)
plt.title("Original Image")
plt.imshow(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
plt.axis("off")

plt.subplot(1, 2, 2)
plt.title("Detected Contour")
plt.imshow(cv2.cvtColor(output_image, cv2.COLOR_BGR2RGB))
plt.axis("off")
plt.show()
