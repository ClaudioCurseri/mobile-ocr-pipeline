#include "TextRecognition.h"
#include <iostream>
#include <opencv2/opencv.hpp>

std::string TextRecognition::recognize(const cv::Mat& image) const {
    return api->GetUTF8Text();
}

