#ifndef TEXTRECOGNITION_H
#define TEXTRECOGNITION_H
#include <string>
#include <tesseract/baseapi.h>
#include <opencv2/opencv.hpp>

class TextRecognition {
public:
    explicit TextRecognition(tesseract::TessBaseAPI *api) : api(api) {}

    std::string recognize(const cv::Mat& image) const;

private:
    tesseract::TessBaseAPI* api;
};


#endif //TEXTRECOGNITION_H
