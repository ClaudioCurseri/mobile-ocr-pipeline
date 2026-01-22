#include "Preprocessing.h"
#include <opencv2/opencv.hpp>

Preprocessing::Preprocessing() {
    this->api = new tesseract::TessBaseAPI();
    if (this->api->Init(nullptr, "osd")) {
        std::cerr << "Could not initialize tesseract." << std::endl;
        return;
    }
    this->api->SetPageSegMode(tesseract::PSM_OSD_ONLY);
}

Preprocessing::~Preprocessing() {
    this->api->End();
    delete this->api;
}


cv::Mat Preprocessing::preprocessingStep() {
    // TODO: implement all preprocessing steps
    correctPageOrientation();
    return this->image;
}

void Preprocessing::setImage(const cv::Mat &image) {
    this->image = image;
    this->api->SetImage(image.data, image.cols, image.rows, image.channels(), image.step);
}


void Preprocessing::showImage() {
    cv::namedWindow("Preprocessing result", cv::WINDOW_AUTOSIZE);
    cv::imshow("Preprocessing result", this->image);
    cv::waitKey(0);
}

void Preprocessing::correctPageOrientation() {
    // FIXME: fix accuracy of this step
    // downscale image for better performance
    cv::Mat lowResImage;
    if (this->image.cols > 1024) {
        const double scaleFactor = 1024.0 / this->image.cols;
        cv::resize(this->image, lowResImage, cv::Size(), scaleFactor, scaleFactor);
    } else {
        lowResImage = this->image.clone();
    }

    this->api->SetImage(lowResImage.data, lowResImage.cols, lowResImage.rows,
                        lowResImage.channels(), lowResImage.step);

    // perform osd
    int orient_deg;
    float orient_conf;
    const char* script_name;
    float script_conf;
    this->api->DetectOrientationScript(&orient_deg, &orient_conf, &script_name, &script_conf);

    if (orient_deg == 0) {
        return;
    }

    cv::Mat tempImage;

    if (orient_deg == 90) {
        cv::rotate(image, tempImage, cv::ROTATE_90_CLOCKWISE);
    } else if (orient_deg == 180) {
        cv::rotate(image, tempImage, cv::ROTATE_180);
    } else if (orient_deg == 270) {
        cv::rotate(image, tempImage, cv::ROTATE_90_COUNTERCLOCKWISE);
    }
    this->image = tempImage;
}
