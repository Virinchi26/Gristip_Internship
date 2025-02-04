import cv2
import numpy as np
import matplotlib.pyplot as plt
import random

# Load the image
image_path = "V:\Web_Development\Gristip_Internship\Task_2\input_length.png"
image = cv2.imread(image_path)

# Convert to grayscale
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

# Apply threshold to detect white shades
_, thresholded = cv2.threshold(gray, 200, 255, cv2.THRESH_BINARY)

# Find contours of white regions
contours, _ = cv2.findContours(thresholded, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

# Create an output image
output = image.copy()

# Minimum area constraint
min_area = 5000  # Adjust this value as needed

# Assign unique colors to each detected area
for contour in contours:
    if cv2.contourArea(contour) >= min_area:
        color = [random.randint(0, 255) for _ in range(3)]  # Generate a random color
        cv2.drawContours(output, [contour], -1, color, thickness=cv2.FILLED)

# Convert BGR to RGB for display
output_rgb = cv2.cvtColor(output, cv2.COLOR_BGR2RGB)

# Show the result
plt.figure(figsize=(10, 6))
plt.imshow(output_rgb)
plt.axis("off")
plt.show()

# Save the output image
output_path = "output_marked.png"
cv2.imwrite(output_path, output)
print(f"Processed image saved to: {output_path}")
