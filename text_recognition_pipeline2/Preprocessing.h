#ifndef PREPROCESSING_H
#define PREPROCESSING_H
#include <tesseract/baseapi.h>
#include <opencv2/opencv.hpp>


class Preprocessing {
public:
    Preprocessing();
    ~Preprocessing();
    void setImage(const cv::Mat &image);

    cv::Mat preprocessingStep();
    void showImage();
private:
    tesseract::TessBaseAPI *api;
    cv::Mat image;
    void correctPageOrientation();
};



#endif //PREPROCESSING_H
