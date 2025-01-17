import cv2
import numpy as np
from PIL import Image

# Function to remove the background around the courier and isolate the courier object
def remove_background(image_path, threshold=240):
    # Load the image using OpenCV
    image = cv2.imread(image_path)
    
    # Convert the image to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # Threshold the image to isolate white regions (assumed background)
    _, thresholded = cv2.threshold(gray, threshold, 255, cv2.THRESH_BINARY)
    
    # Invert the thresholded image to get the courier's mask (non-white area)
    inverted_thresholded = cv2.bitwise_not(thresholded)
    
    # Find contours of the courier (non-white area)
    contours, _ = cv2.findContours(inverted_thresholded, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    # Create a mask for the courier
    mask = np.zeros_like(image, dtype=np.uint8)
    cv2.drawContours(mask, contours, -1, (255, 255, 255), thickness=cv2.FILLED)
    
    # Use the mask to remove the background (make the background transparent)
    courier_only = cv2.bitwise_and(image, mask)
    
    # Convert the image to BGRA to add alpha transparency
    courier_only_with_alpha = cv2.cvtColor(courier_only, cv2.COLOR_BGR2BGRA)
    
    # Set the background (non-courier) to transparent (alpha=0)
    courier_only_with_alpha[:, :, 3] = np.where(courier_only_with_alpha[:, :, :3].sum(axis=2) == 0, 0, 255)
    
    return courier_only_with_alpha

# Function to detect the white rectangular mask inside the courier and visualize it
def find_white_rectangular_mask_inside_courier(image_path, threshold=240, min_area=500):
    # Load the background removed image (already isolated the courier)
    image = cv2.imread(image_path, cv2.IMREAD_UNCHANGED)  # Load with alpha channel
    
    # Convert the image to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGRA2GRAY)
    
    # Threshold the image to isolate white regions (the white mask inside the courier)
    _, thresholded = cv2.threshold(gray, threshold, 255, cv2.THRESH_BINARY)
    
    # Find contours of the white regions
    contours, _ = cv2.findContours(thresholded, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    # List to store the detected rectangular regions
    rects = []
    
    for contour in contours:
        # Get the bounding box of each contour
        x, y, w, h = cv2.boundingRect(contour)
        
        # Filter based on area size (to avoid small noise)
        if cv2.contourArea(contour) > min_area:
            # Check if the contour has a rectangular shape by checking its aspect ratio
            aspect_ratio = float(w) / h
            if 0.3 < aspect_ratio < 3:  # Relax the aspect ratio range
                rects.append((x, y, w, h))
                # Draw the rectangle on the image
                cv2.rectangle(image, (x, y), (x + w, y + h), (0, 255, 0, 255), 2)  # Green color rectangle
    
    # Save the image with rectangles drawn around the detected areas
    cv2.imwrite("detected_rectangles_inside_courier.png", image)
    print("Rectangles visualized and saved as 'detected_rectangles_inside_courier.png'.")
    
    return rects, image

# Example usage
background_image_path = "V:\Web_Development\Gristip_Internship\Task_2\input_test.png"  # Path to your courier image

# Remove the background around the courier
courier_image = remove_background(background_image_path)

# Save the courier image with transparent background (for later use)
cv2.imwrite("courier_with_transparent_background.png", courier_image)
print("Background removed and saved as 'courier_with_transparent_background.png'.")

# Find the white rectangular mask inside the courier and visualize it
rectangles, visualized_image = find_white_rectangular_mask_inside_courier("courier_with_transparent_background.png")

# Optionally, open the visualized image to inspect it
visualized_pil_image = Image.fromarray(cv2.cvtColor(visualized_image, cv2.COLOR_BGRA2RGBA))
visualized_pil_image.show()
