import cv2
import numpy as np
import matplotlib.pyplot as plt

# Load the image
image_path = 'V:\Web_Development\Gristip_Internship\Task_2\input_breadth.png'
image = cv2.imread(image_path)

# Convert the image to grayscale
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

# Apply a binary threshold to isolate white regions
_, thresholded = cv2.threshold(gray, 240, 255, cv2.THRESH_BINARY)

# Find contours of the white areas
contours, _ = cv2.findContours(thresholded, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

# Filter contours to find the largest rectangular white area
largest_contour = None
max_area = 0
for contour in contours:
    x, y, w, h = cv2.boundingRect(contour)
    area = w * h
    if area > max_area:
        max_area = area
        largest_contour = contour

# Draw the largest rectangle on the original image
output_image = image.copy()
if largest_contour is not None:
    x, y, w, h = cv2.boundingRect(largest_contour)
    cv2.rectangle(output_image, (x, y), (x + w, y + h), (0, 255, 0), 2)
    print(f"Largest white rectangle - x: {x}, y: {y}, width: {w}, height: {h}")
else:
    print("No large white rectangle found.")

# Display or save the output image
output_path = 'V:\Web_Development\Gristip_Internship\Task_2\output_with_white_space.png'
cv2.imwrite(output_path, output_image)

# Show the image with detected white space
plt.imshow(cv2.cvtColor(output_image, cv2.COLOR_BGR2RGB))
plt.title("Detected Largest White Space")
plt.axis("off")
plt.show()
