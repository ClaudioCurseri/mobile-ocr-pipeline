#include "Preprocessing.h"
#include <opencv2/opencv.hpp>

cv::Mat Preprocessing::preprocessingStep() {
    convertToBinaryImage();
    applyMedianFilter();
    dewarpImage();
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

void Preprocessing::convertToBinaryImage() {
    cv::cvtColor(this->internalImage, this->internalImage, cv::COLOR_RGB2GRAY);
    cv::adaptiveThreshold(this->internalImage, this->internalImage, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 5);
}

void Preprocessing::applyMedianFilter() {
    cv::medianBlur(this->internalImage, this->internalImage, 5);
}

void Preprocessing::resizeImage() {
    constexpr int targetWidth = 2480;
    constexpr int targetHeight = 3508;
    const auto targetSize = cv::Size(targetWidth, targetHeight);
    cv::resize(this->internalImage, this->internalImage, targetSize);
}

std::vector<cv::Point2f> orderPoints(const std::vector<cv::Point>& pts) {
    std::vector<cv::Point2f> rect(4);

    auto sumComp = [](const cv::Point& a, const cv::Point& b) { return a.x + a.y < b.x + b.y; };
    auto diffComp = [](const cv::Point& a, const cv::Point& b) { return a.y - a.x < b.y - b.x; };

    // find top left (min sum) and bottom right (max sum)
    const auto [tl, br] = std::minmax_element(pts.begin(), pts.end(), sumComp);
    rect[0] = *tl;
    rect[2] = *br;

    // find top right (min diff) and bottom left (max diff)
    const auto [tr, bl] = std::minmax_element(pts.begin(), pts.end(), diffComp);
    rect[1] = *tr;
    rect[3] = *bl;

    return rect;
}

void Preprocessing::dewarpImage() {
    // edge detection
    cv::Mat edged;
    cv::Canny(this->internalImage, edged, 30, 100);

    // dilation -> all structures grow, increases chance of finding the document contours
    cv::Mat dilated;
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(11, 11));
    cv::dilate(edged, dilated, kernel, cv::Point(-1, -1), 2);

    // find all contours
    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(dilated, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);

    // sort found contours in descending order
    std::ranges::sort(contours, [](const std::vector<cv::Point>& c1, const std::vector<cv::Point>& c2) {
        return cv::contourArea(c1) > cv::contourArea(c2);
    });

    std::vector<cv::Point> documentContour;
    bool found = false;

    // calculate total image area
    double imageArea = this->internalImage.rows * this->internalImage.cols;

    // find the document contours
    for (const auto& contour : contours) {
        // do not accept contours that are too small
        if (double area = cv::contourArea(contour); area < imageArea * 0.1) {
            continue;
        }

        double perimeter = cv::arcLength(contour, true);
        std::vector<cv::Point> approx;

        cv::approxPolyDP(contour, approx, 0.03 * perimeter, true);

        if (approx.size() == 4) {
            documentContour = approx;
            found = true;
            break;
        }
    }

    // document contours not found
    if (!found) {
        std::cerr << "Unable to find document contours. Returning original image." << std::endl;
        return;
    }

    // transform the image
    std::vector<cv::Point2f> rect = orderPoints(documentContour);

    // calculate new image dimensions
    float widthA = static_cast<float>(cv::norm(rect[2] - rect[3])); // BR - BL
    float widthB = static_cast<float>(cv::norm(rect[1] - rect[0])); // TR - TL
    int maxWidth = std::max(static_cast<int>(widthA), static_cast<int>(widthB));

    float heightA = static_cast<float>(cv::norm(rect[1] - rect[2])); // TR - BR
    float heightB = static_cast<float>(cv::norm(rect[0] - rect[3])); // TL - BL
    int maxHeight = std::max(static_cast<int>(heightA), static_cast<int>(heightB));

    std::vector destinationPoints = {
        cv::Point2f(0, 0),
        cv::Point2f(static_cast<float>(maxWidth) - 1, 0),
        cv::Point2f(static_cast<float>(maxWidth) - 1, static_cast<float>(maxHeight) - 1),
        cv::Point2f(0, static_cast<float>(maxHeight) - 1)
    };

    // apply image transformation
    cv::Mat M = cv::getPerspectiveTransform(rect, destinationPoints);
    cv::warpPerspective(this->internalImage, this->internalImage, M, cv::Size(maxWidth, maxHeight));
}