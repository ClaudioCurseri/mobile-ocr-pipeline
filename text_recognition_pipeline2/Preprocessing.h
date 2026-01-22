#ifndef PREPROCESSING_H
#define PREPROCESSING_H
#include <tesseract/baseapi.h>
#include <opencv2/opencv.hpp>


class Preprocessing {
public:
    cv::Mat preprocessingStep(const cv::Mat& image);
    void showImage(const cv::Mat& image);
};



#endif //PREPROCESSING_H
