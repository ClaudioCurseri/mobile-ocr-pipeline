#include "TextRecognition.h"
#include <iostream>
#include <opencv2/opencv.hpp>

std::string TextRecognition::recognize(const cv::Mat& image) const {
    api->SetPageSegMode(tesseract::PSM_AUTO);
    api->SetImage(image.data, image.cols, image.rows, 3, image.step);
    return api->GetUTF8Text();
}

