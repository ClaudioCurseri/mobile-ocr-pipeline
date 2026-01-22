#include "Preprocessing.h"
#include <opencv2/opencv.hpp>

cv::Mat Preprocessing::preprocessingStep(const cv::Mat& image) {
    // TODO: implement preprocessing steps
    return image;
}

void Preprocessing::showImage(const cv::Mat& image) {
    cv::namedWindow("Preprocessing result", cv::WINDOW_AUTOSIZE);
    cv::imshow("Preprocessing result", image);
    cv::waitKey(0);
}