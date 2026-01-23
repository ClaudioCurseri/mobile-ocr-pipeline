#include "Preprocessing.h"
#include <opencv2/opencv.hpp>

Preprocessing::Preprocessing() {
    this->api = new tesseract::TessBaseAPI();
    if (this->api->Init(nullptr, "osd", tesseract::OEM_TESSERACT_ONLY)) {
        std::cerr << "Could not initialize tesseract." << std::endl;
        return;
    }
    this->api->SetPageSegMode(tesseract::PageSegMode::PSM_OSD_ONLY);
}

Preprocessing::~Preprocessing() {
    this->api->End();
    delete this->api;
}

cv::Mat Preprocessing::preprocessingStep() {
    // TODO: implement all preprocessing steps
    convertToGrayscale();
    convertToBinary();
    medianFilter();
    correctPageOrientation();
    resizeImage();
    this->image = this->internalImage.clone();
    return this->image;
}

void Preprocessing::setImage(const cv::Mat &image) {
    this->image = image;
    this->internalImage = this->image.clone();
}

void Preprocessing::showImage() const {
    cv::namedWindow("Preprocessing result", cv::WINDOW_AUTOSIZE);
    cv::imshow("Preprocessing result", this->image);
    cv::waitKey(0);
}

void Preprocessing::correctPageOrientation() {
    // set tesseract image
    this->api->SetImage(this->internalImage.data, this->internalImage.cols, this->internalImage.rows,
                        this->internalImage.channels(), this->internalImage.step);
    // perform osd
    int orient_deg;
    float orient_conf;
    const char* script_name;
    float script_conf;
    this->api->DetectOrientationScript(&orient_deg, &orient_conf, &script_name, &script_conf);
    // correct orientation
    switch (orient_deg) {
        case 90:
            cv::rotate(this->internalImage, this->internalImage, cv::ROTATE_90_COUNTERCLOCKWISE);
            break;
        case 180:
            cv::rotate(this->internalImage, this->internalImage, cv::ROTATE_180);
            break;
        case 270:
            cv::rotate(this->internalImage, this->internalImage, cv::ROTATE_90_CLOCKWISE);
            break;
        default:
    }
}

void Preprocessing::convertToGrayscale() {
    cv::cvtColor(this->internalImage, this->internalImage, cv::COLOR_RGB2GRAY);
}

void Preprocessing::convertToBinary() {
    cv::adaptiveThreshold(this->internalImage, this->internalImage, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 5);
}

void Preprocessing::medianFilter() {
    cv::medianBlur(this->internalImage, this->internalImage, 5);
}

void Preprocessing::resizeImage() {
    constexpr int targetWidth = 2480;
    constexpr int targetHeight = 3508;
    const auto targetSize = cv::Size(targetWidth, targetHeight);
    cv::resize(this->internalImage, this->internalImage, targetSize);
}

