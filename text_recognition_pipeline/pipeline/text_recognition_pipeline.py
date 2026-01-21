import cv2
from cv2.typing import MatLike
from pipeline.preprocessing import Preprocessing
from pipeline.text_recognition import TextRecognition

class TextRecognitionPipeline:

    def __init__(self):
        self._preprocessing = Preprocessing()
        self._text_recognition = TextRecognition()

    def run(self, document: str):
        """
        Run the OCR pipeline for one document.
        
        :param document: Path to the document file.
        :type document: str
        """
        image: MatLike = cv2.imread(document)
        
        preprocessed_image: MatLike = self._preprocessing.preprocessingStep(image)

        recognition_result = self._text_recognition.recognizeText(preprocessed_image)

        return self._convert_to_gt_format(recognition_result)
    
    def _convert_to_gt_format(self, recognition_output: dict):
        """
        Converts the recognition result to the ground truth format.
        
        :param recognition_output: Recognition result.
        :type recognition_output: dict
        """
        text_output = []
    
        last_block = -1
        last_par = -1
        last_line = -1

        n_boxes = len(recognition_output['level'])

        for i in range(n_boxes):
            if recognition_output['level'][i] != 5:
                continue

            text = recognition_output['text'][i]

            if not text.strip():
                continue

            separator = ""

            curr_block = recognition_output['block_num'][i]
            curr_par = recognition_output['par_num'][i]
            curr_line = recognition_output['line_num'][i]

            if last_block != -1:
                if curr_block != last_block or curr_par != last_par or curr_line != last_line:
                    separator = "\n"
                else:
                    separator = " "

            text_output.append(separator + text)

            last_block = curr_block
            last_par = curr_par
            last_line = curr_line

        return "".join(text_output)
        


        