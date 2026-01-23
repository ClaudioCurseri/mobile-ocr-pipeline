#ifndef PREPROCESSING_H
#define PREPROCESSING_H
#include <opencv2/opencv.hpp>


class Preprocessing {
public:
    void setImage(const cv::Mat &image);
    cv::Mat preprocessingStep();
    void showImage() const;
private:
    cv::Mat image;
    cv::Mat internalImage;
    void convertToBinaryImage();
    void applyMedianFilter();
    void resizeImage();
    void dewarpImage();
};



#endif //PREPROCESSING_H
