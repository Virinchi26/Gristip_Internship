import cv2
import numpy as np
import matplotlib.pyplot as plt

# Load the image
image = cv2.imread('V:\Web_Development\Gristip_Internship\Task_2\input_breadth.png')

# Define the coordinates for the rectangular region
top_left = (143, 152)  # (x1, y1)
bottom_right = (315, 401)  # (x2, y2)

# Crop the region from the image using the coordinates
cropped_region = image[top_left[1]:bottom_right[1], top_left[0]:bottom_right[0]]

# Show the original image and the cropped region using matplotlib
image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
cropped_rgb = cv2.cvtColor(cropped_region, cv2.COLOR_BGR2RGB)

plt.figure(figsize=(10, 5))

plt.subplot(1, 2, 1)
plt.title('Original Image')
plt.imshow(image_rgb)
plt.axis('off')

plt.subplot(1, 2, 2)
plt.title('Extracted Region')
plt.imshow(cropped_rgb)
plt.axis('off')

plt.show()
