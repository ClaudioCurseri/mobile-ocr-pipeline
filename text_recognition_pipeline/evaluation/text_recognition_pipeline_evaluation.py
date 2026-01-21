from pipeline.text_recognition_pipeline import TextRecognitionPipeline

class TextRecognitionPipelineEvaluation:

    def __init__(self, pipeline: TextRecognitionPipeline):
        self._pipeline = pipeline

    def visualize_result(self):
        """
        Visualize the result of the recongition result by displaying the generated bounding boxes and the document picture.
        """