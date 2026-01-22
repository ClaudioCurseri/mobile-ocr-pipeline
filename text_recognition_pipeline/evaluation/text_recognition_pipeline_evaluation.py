from pipeline.text_recognition_pipeline import TextRecognitionPipeline
import cv2
from cv2.typing import MatLike
import matplotlib.pyplot as plt

class TextRecognitionPipelineEvaluation:

    def __init__(self, pipeline: TextRecognitionPipeline):
        self._pipeline = pipeline

    def visualize_result(self, document: str):
        """
        Visualize the result of the recongition result by displaying the generated bounding boxes and the document picture.
        """
        result: dict = self._pipeline.run(document=document, output_as_gt=False)
        image = cv2.imread(document)
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        n_boxes = len(result["text"])

        for position in range(n_boxes):
            if result["conf"][position] == -1: continue
            # bounding box position
            x, y = result["left"][position], result["top"][position]
            w, h = result["width"][position], result["height"][position]
            # bounding box corners
            top_left = (x, y)
            bottom_right = (x + w, y + h)
            # bounding box parameters
            color = (0, 255, 0)
            box_thickness = 3
            # draw rectangle
            cv2.rectangle(img=image, pt1=top_left, pt2=bottom_right, color=color, thickness=box_thickness)
        # show the image
        plt.figure(figsize=(12, 12))
        plt.imshow(image)
        plt.axis('off')
        plt.show()

