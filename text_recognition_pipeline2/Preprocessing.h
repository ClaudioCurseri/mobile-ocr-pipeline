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
    void showImage() const;
private:
    tesseract::TessBaseAPI *api;
    cv::Mat image;
    cv::Mat internalImage;
    void correctPageOrientation();
    void convertToGrayscale();
    void convertToBinary();
    void medianFilter();
    void resizeImage();
};



#endif //PREPROCESSING_H
