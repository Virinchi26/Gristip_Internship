import cv2
import numpy as np

def detect_edges(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    edges = cv2.Canny(blurred, 50, 150)
    return edges

def find_contours(edges):
    contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    return contours

def find_largest_contour(contours):
    largest_contour = max(contours, key=cv2.contourArea)
    return largest_contour

def detect_white_space(image, contour):
    x, y, w, h = cv2.boundingRect(contour)
    roi = image[y:y+h, x:x+w]
    gray_roi = cv2.cvtColor(roi, cv2.COLOR_BGR2GRAY)
    _, binary_roi = cv2.threshold(gray_roi, 240, 255, cv2.THRESH_BINARY)
    
    white_space_contours, _ = cv2.findContours(binary_roi, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    return white_space_contours

def main(image_path):
    image = cv2.imread(image_path)
    edges = detect_edges(image)
    contours = find_contours(edges)
    largest_contour = find_largest_contour(contours)
    
    white_space_contours = detect_white_space(image, largest_contour)
    
    for contour in white_space_contours:
        x, y, w, h = cv2.boundingRect(contour)
        cv2.rectangle(image, (x, y), (x+w, y+h), (0, 255, 0), 2)
    
    output_path = 'V:/Web_Development/Gristip_Internship/Task_2/output.png'
    cv2.imwrite(output_path, image)
    print(f'Result saved to {output_path}')

if __name__ == "__main__":
    image_path = 'V:\Web_Development\Gristip_Internship\Task_2\input_breadth.png'
    main(image_path)