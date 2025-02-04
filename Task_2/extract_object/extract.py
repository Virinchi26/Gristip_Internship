import cv2

# Load the original image
image = cv2.imread('V:\Web_Development\Gristip_Internship\Task_2\input_breadth.png')

# Define the coordinates for the rectangular region
top_left = (143, 152)  # (x1, y1)
bottom_right = (315, 401)  # (x2, y2)

# Crop the region from the image using the coordinates
cropped_region = image[top_left[1]:bottom_right[1], top_left[0]:bottom_right[0]]

# Save the cropped region as a separate file
cv2.imwrite('extracted_region.jpg', cropped_region)

print("Extracted region saved as 'extracted_region.jpg'")
