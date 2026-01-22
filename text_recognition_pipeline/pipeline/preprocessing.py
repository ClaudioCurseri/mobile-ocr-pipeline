import cv2
from cv2.typing import MatLike
import pytesseract
from pytesseract import Output

class Preprocessing:

    def __init__(self):
        pass

    def preprocessingStep(self, image: MatLike) -> MatLike:
        # TODO Implement preprocessing steps
        #image = self._correctPageOrientation(image)
        return image
    

    def _correctPageOrientation(self, image: MatLike) -> MatLike:
        osd_result = pytesseract.image_to_osd(image, output_type=Output.DICT)
        rotation_angle = osd_result["rotate"]
        
        if rotation_angle == 90:
            rotated_image = cv2.rotate(image, cv2.ROTATE_90_CLOCKWISE)
        elif rotation_angle == 180:
            rotated_image = cv2.rotate(image, cv2.ROTATE_180)
        elif rotation_angle == 270:
            rotated_image = cv2.rotate(image, cv2.ROTATE_90_COUNTERCLOCKWISE)

        return rotated_image
