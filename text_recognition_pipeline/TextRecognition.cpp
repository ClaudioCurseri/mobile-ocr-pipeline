#include "TextRecognition.h"
#include <iostream>
#include <opencv2/opencv.hpp>

tesseract::ResultIterator* TextRecognition::recognize() const {
    this->api->Recognize(nullptr);
    return this->api->GetIterator();
}

