import cv2
import numpy as np

# Function to extract and save the region from the original image
def extract_and_save_region(image_path, top_left, bottom_right, output_path):
    # Load the original image
    image = cv2.imread(image_path)

    # Crop the region from the image using the coordinates
    cropped_region = image[top_left[1]:bottom_right[1], top_left[0]:bottom_right[0]]

    # Save the cropped region as a separate file
    cv2.imwrite(output_path, cropped_region)
    print(f"Extracted region saved as {output_path}")

# Function to match the extracted region in a new image
def match_region_in_new_image(new_image_path, template_path):
    # Load the new image where the region needs to be detected
    new_image = cv2.imread(new_image_path)

    # Load the extracted region (template)
    template = cv2.imread(template_path, cv2.IMREAD_GRAYSCALE)

    # Convert the new image to grayscale for feature matching
    new_image_gray = cv2.cvtColor(new_image, cv2.COLOR_BGR2GRAY)

    # Use ORB (Oriented FAST and Rotated BRIEF) detector
    orb = cv2.ORB_create()

    # Find keypoints and descriptors in the template (extracted region)
    keypoints1, descriptors1 = orb.detectAndCompute(template, None)

    # Find keypoints and descriptors in the new image
    keypoints2, descriptors2 = orb.detectAndCompute(new_image_gray, None)

    # Use BFMatcher (Brute-Force Matcher) to match descriptors
    bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)

    # Match descriptors
    matches = bf.match(descriptors1, descriptors2)

    # Sort matches based on distance (the smaller, the better)
    matches = sorted(matches, key=lambda x: x.distance)

    # Draw the matches on the new image
    result_image = cv2.drawMatches(template, keypoints1, new_image, keypoints2, matches[:10], None, flags=cv2.DrawMatchesFlags_NOT_DRAW_SINGLE_POINTS)

    # Show the result
    cv2.imshow('Matched Features', result_image)
    cv2.waitKey(0)
    cv2.destroyAllWindows()

    return matches, keypoints1, keypoints2

# Function to extract the region based on matched keypoints
def extract_matched_region(new_image_path, template_path, matches, keypoints1, keypoints2):
    # If there are fewer than 4 matches, don't calculate the homography
    if len(matches) < 4:
        print("Not enough matches to calculate homography.")
        return

    # Load the new image and template
    new_image = cv2.imread(new_image_path)
    template = cv2.imread(template_path, cv2.IMREAD_GRAYSCALE)

    # Filter the matches using Lowe's ratio test (to improve quality of matches)
    good_matches = []
    for m, n in zip(matches[:-1], matches[1:]):
        if m.distance < 0.75 * n.distance:  # Lowe's ratio test
            good_matches.append(m)

    # If there are still fewer than 4 good matches, exit
    if len(good_matches) < 4:
        print("Not enough good matches to calculate homography.")
        return

    # Find the homography (transformation matrix) between the matched keypoints
    src_pts = np.float32([keypoints1[m.queryIdx].pt for m in good_matches]).reshape(-1, 1, 2)
    dst_pts = np.float32([keypoints2[m.trainIdx].pt for m in good_matches]).reshape(-1, 1, 2)

    # Calculate the perspective transform (homography)
    M, mask = cv2.findHomography(src_pts, dst_pts, cv2.RANSAC, 5.0)

    # Get the dimensions of the template (extracted region)
    h, w = template.shape

    # Warp the perspective of the template to match the region in the new image
    warped_region = cv2.warpPerspective(template, M, (new_image.shape[1], new_image.shape[0]))

    # Get the bounding box for the warped region
    x, y, w, h = cv2.boundingRect(warped_region)

    # Crop the warped region from the new image
    extracted_from_new_image = new_image[y:y+h, x:x+w]

    # Save the cropped region from the new image
    cv2.imwrite('extracted_from_new_image.jpg', extracted_from_new_image)
    print("Extracted region saved as 'extracted_from_new_image.jpg'")

    # Show the extracted region
    cv2.imshow('Extracted Region from New Image', extracted_from_new_image)
    cv2.waitKey(0)
    cv2.destroyAllWindows()

# Main workflow

# Step 1: Extract and save the region from the original image
original_image_path = 'V:\Web_Development\Gristip_Internship\Task_2\input_breadth.png'
top_left = (143, 152)  # (x1, y1)
bottom_right = (315, 401)  # (x2, y2)
output_path = 'extracted_region.jpg'
extract_and_save_region(original_image_path, top_left, bottom_right, output_path)

# Step 2: Match the region in a new image
new_image_path = 'V:\Web_Development\Gristip_Internship\Task_2\input_breadth.png'  # Update with the new image path
matches, keypoints1, keypoints2 = match_region_in_new_image(new_image_path, output_path)

# Step 3: Extract the region based on the matched keypoints
extract_matched_region(new_image_path, output_path, matches, keypoints1, keypoints2)
