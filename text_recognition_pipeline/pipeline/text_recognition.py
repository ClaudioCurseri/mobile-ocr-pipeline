from cv2.typing import MatLike
import pytesseract
from pytesseract import Output

class TextRecognition:

    def __init__(self):
        pass

    def recognizeText(self, image: MatLike):
        return pytesseract.image_to_data(image, output_type=Output.DICT)
