#include "text_recognition_pipeline.h"
#include <syslog.h>

TextRecognitionPipeline::~TextRecognitionPipeline() {
    this->api->End();
}


void TextRecognitionPipeline::preprocessingStep(const PreprocessingConfig config) {
    if (config.grayscale) convertToGrayscale();
    if (config.dewarp) dewarpImage();
    if (config.unsharpMasking) unsharpMasking();
    if (config.binary) convertToBinaryImage();
    if (config.resize) resizeImage();
    this->image = this->internalImage.clone();
    this->api->SetImage(this->internalImage.data, this->internalImage.cols, this->internalImage.rows, this->internalImage.channels(), this->internalImage.step);
}

void TextRecognitionPipeline::setImage(const char* imagePath) {
    const auto image = cv::imread(imagePath, cv::IMREAD_COLOR);
    this->image = image;
    this->internalImage = this->image.clone();
    this->api->SetImage(image.data, image.cols, image.rows, image.channels(), image.step);
}

cv::Mat TextRecognitionPipeline::getImage() {
    return this->image;
}

void TextRecognitionPipeline::convertToGrayscale() {
    cv::cvtColor(this->internalImage, this->internalImage, cv::COLOR_RGB2GRAY);
}

void TextRecognitionPipeline::convertToBinaryImage() {
    if (this->internalImage.channels() > 1) {
        cv::cvtColor(this->internalImage, this->internalImage, cv::COLOR_RGB2GRAY);
    }
    cv::adaptiveThreshold(this->internalImage, this->internalImage, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 5);
    cv::medianBlur(this->internalImage, this->internalImage, 5);
}

void TextRecognitionPipeline::unsharpMasking() {
    cv::Mat blurred;
    cv::GaussianBlur(this->internalImage, blurred, cv::Size(0, 0), 1);
    cv::addWeighted(this->internalImage, 1.5, blurred, -0.5, 0, this->internalImage);
}

void TextRecognitionPipeline::resizeImage() {
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

void TextRecognitionPipeline::dewarpImage() {
    // make sure we always work with a grayscale image to detect the edges better
    cv::Mat gray;
    cv::cvtColor(this->image, gray, cv::COLOR_RGB2GRAY);

    cv::GaussianBlur(gray, gray, cv::Size(5, 5), 0);

    // edge detection
    cv::Mat edged;
    cv::Canny(gray, edged, 75, 200);

    // edge detection was too strict and made the picture mostly black?
    // -> then try again with lower thresholds
    if (cv::countNonZero(edged) < 200000) {
        cv::Canny(gray, edged, 30, 100);
    }

    // dilation -> all structures grow, increases chance of finding the document contours
    cv::Mat dilated;
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(11, 11));
    cv::dilate(edged, dilated, kernel, cv::Point(-1, -1), 1);
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
        double area = cv::contourArea(contour);
        // do not accept contours that are too small
        if ( area < imageArea * 0.1) {
            continue;
        }

        double perimeter = cv::arcLength(contour, true);
        std::vector<cv::Point> approx;
        // try to find four contours
        for (double epsilon = 0.02; epsilon <= 0.05; epsilon += 0.01) {
            cv::approxPolyDP(contour, approx, epsilon * perimeter, true);

            if (approx.size() == 4) {
                    documentContour = approx;
                    found = true;
                    goto end_search;
            }
        }
        // did not find four contours? -> try to use the min rect within the given points
        if (area > imageArea * 0.2) {
            cv::RotatedRect rect = cv::minAreaRect(contour);
            cv::Point2f pts[4];
            rect.points(pts);
            for (auto pt : pts) documentContour.push_back(pt);
            found = true;
            goto end_search;
        }
    }
end_search:
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


void TextRecognitionPipeline::initTesseract(const char* filepath) {
    this->api = new tesseract::TessBaseAPI();
    if (api->Init(filepath, "eng", tesseract::OEM_LSTM_ONLY)) {
        std::cerr << "Could not initialize tesseract." << std::endl;
        syslog(LOG_ALERT, "Could not initialize tesseract.");
        syslog(LOG_ALERT, "%s", filepath);
        return;
    }
    api->SetPageSegMode(tesseract::PSM_AUTO);
}


void TextRecognitionPipeline::textRecognitionStep() {
    try {
        this->api->Recognize(nullptr);
        this->tesseractRecognitionResult = this->api->GetIterator();
    } catch (const std::exception& e) {
        syslog(LOG_ALERT, "TextRecognitionPipeline::textRecognitionStep - %s", e.what());
    }
}


int TextRecognitionPipeline::initBigramDictionary(const char *filepath) {
    this->biStore = std::make_unique<yams::symspell::MemoryStore>(2, 7);
    this->biSymspell = std::make_unique<yams::symspell::SymSpell>(std::move(this->biStore), 2, 7);
    std::ifstream dictionary(filepath);
    if (!dictionary.is_open()) {
        std::cerr << "Error: Could not open file." << std::endl;
        return -1;
    }
    std::string word1, word2;
    long long frequency;

    while (dictionary >> word1 >> word2 >> frequency) {
        std::string key = word1 + " " + word2;
        this->biSymspell->createDictionaryEntry(key, frequency);
    }
    std::cout << "Initialised bigram dictionary." << std::endl;
    return 0;
}

int TextRecognitionPipeline::initUnigramDictionary(const char *filepath) {
    this->store = std::make_unique<yams::symspell::MemoryStore>(2, 7);
    this->symspell = std::make_unique<yams::symspell::SymSpell>(std::move(this->store), 2, 7);
    std::ifstream dictionary(filepath);
    if (!dictionary.is_open()) {
        std::cerr << "Error: Could not open file." << std::endl;
        return -1;
    }
    std::string word;
    long long frequency;
    while (dictionary >> word >> frequency) {
        this->symspell->createDictionaryEntry(word, frequency);
        this->totalUnigramCount += frequency;
    }
    std::cout << "Initialised unigram dictionary." << std::endl;
    return 0;
}

void TextRecognitionPipeline::postprocessingStep(PostprocessingConfig config) {
    constexpr tesseract::PageIteratorLevel level = tesseract::RIL_WORD;
    std::vector<std::tuple<int, int, int, int, std::string, bool>> result;
    if (this->tesseractRecognitionResult != nullptr) {
        std::string previousWord;
        do {
            char* rawText = this->tesseractRecognitionResult->GetUTF8Text(level);
            std::string word;
            if (rawText != nullptr) {
                word = std::string(rawText);
                delete[] rawText;
            } else {
                continue;
            }
            if (config.useTopResultFromDictionary) word = replaceWithTopResult(word);
            if (config.useContext) word = replaceWithContext(previousWord, word);
            int x1, y1, x2, y2;
            this->tesseractRecognitionResult->BoundingBox(level, &x1, &y1, &x2, &y2);
            bool is_eol = this->tesseractRecognitionResult->IsAtFinalElement(tesseract::RIL_TEXTLINE, level);
            result.emplace_back(x1, y1, x2, y2, word, is_eol);
            if (is_eol) {
                previousWord = "";
            } else {
                previousWord = word;
            }
        } while (this->tesseractRecognitionResult->Next(level));
    }
    this->recognitionResult = result;
}

std::vector<std::tuple<int, int, int, int, std::string, bool>> TextRecognitionPipeline::getRecognitionResult() {
    return this->recognitionResult;
}

bool isNotAlphanumeric(const std::string &word) {
    return std::ranges::none_of(word, isalnum);
}

bool isNumber(const std::string &word) {
    return std::ranges::any_of(word, isdigit);
}

bool isEqOrShorterThan(const std::string &word, int maxLen) {
    return word.length() <= maxLen;
}

std::string cleanWordForLookup(std::string text) {
    // remove punctuation
    std::erase_if(text, [](const char c) { return std::ispunct(c); });
    // to lowercase
    std::ranges::transform(text, text.begin(),
                           [](unsigned char c){ return std::tolower(c); });
    return text;
}

bool containsPunctuationAtStartOrEnd(const std::string &word) {
    return word.starts_with("(") or word.ends_with(")")
    or word.ends_with(".") or word.ends_with("!") or word.ends_with("?")
    or word.ends_with(",") or word.ends_with(";") or word.ends_with(":");
}

// replaces every word with the top result from the assets ONLY IF the following conditions are met:
// - the word is alphanumeric
// - the word is not a number
// - the word does not contain punctuation symbols at the start or more importantly at the end
// - the word is longer than a given value
// - the word is capitalized
std::string TextRecognitionPipeline::replaceWithTopResult(const std::string &word) const {
    if (isNotAlphanumeric(word) or isNumber(word)
         or isEqOrShorterThan(word, 2)
        or std::isupper(word[0])) return word;
    std::string replacement = word;
    for (const auto suggestion = this->symspell->lookup(cleanWordForLookup(word), yams::symspell::Verbosity::Top,2); const auto& s : suggestion) {
        if (s.distance == 0) return word;
        replacement = s.term;
        std::cout << "Replaced " << word << " with " << replacement << " | Distance: " << s.distance << std::endl;
    }
    return replacement;
}

struct ScoredCandidate {
    std::string term;
    double probability;
};

std::string TextRecognitionPipeline::replaceWithContext(const std::string &previousWord, const std::string &currentWord) const {
    if (isNotAlphanumeric(currentWord) or isNumber(currentWord)
        or containsPunctuationAtStartOrEnd(currentWord) or isEqOrShorterThan(currentWord, 2)
        or std::isupper(currentWord[0])) return currentWord;

    const auto exactMatch = this->symspell->lookup(currentWord, yams::symspell::Verbosity::Top, 0);
    if (!exactMatch.empty()) return currentWord;

    const auto unigramCandidates = this->symspell->lookup(currentWord, yams::symspell::Verbosity::All, 2);
    if (unigramCandidates.empty()) return currentWord;

    const long long N = this->totalUnigramCount > 0 ? this->totalUnigramCount : 1000000;

    std::string prevClean = cleanWordForLookup(previousWord);

    long long previousUnigramCount = 0;
    if (!prevClean.empty()) {
        const auto suggestion = this->symspell->lookup(prevClean, yams::symspell::Verbosity::Top, 0);
        previousUnigramCount = suggestion.empty() ? 0 : suggestion[0].frequency;
    }

    std::vector<ScoredCandidate> candidates;

    for (const auto& candidate : unigramCandidates) {
        constexpr double lambda = 0.8;

        // unigram Probability
        const double pUnigram = static_cast<double>(candidate.frequency) / static_cast<double>(N);

        // bigram Probability
        double pBigram = 0.0;
        if (previousUnigramCount > 0) {
            std::string bigramKey = prevClean + " " + candidate.term;

            const auto suggestion = this->biSymspell->lookup(bigramKey, yams::symspell::Verbosity::Top, 0);

            long long bigramCount = suggestion.empty() ? 0 : suggestion[0].frequency;

            pBigram = static_cast<double>(bigramCount) / static_cast<double>(previousUnigramCount);
        }

        // Jelinek-Mercer Smoothing
        const double probability = lambda * pBigram + (1 - lambda) * pUnigram;

        candidates.push_back(ScoredCandidate{candidate.term, probability});
    }
    std::ranges::sort(candidates, [](const ScoredCandidate &candidate1, const ScoredCandidate &candidate2) {
        return candidate1.probability > candidate2.probability;
    });
    return candidates.empty() ? currentWord : candidates.front().term;
}

// --------------------- C adapter methods ---------------------

TextRecognitionPipeline* TextRecognition_create() {
    return new TextRecognitionPipeline();
}

void TextRecognition_destroy(const TextRecognitionPipeline* pipeline) {
        delete pipeline;
}

void TextRecognition_setImage(TextRecognitionPipeline* pipeline, const char* imagePath) {
    if (pipeline != nullptr) pipeline->setImage(imagePath);
}

void TextRecognition_preprocessingStep(TextRecognitionPipeline* pipeline, const C_PreprocessingConfig config) {
    if (pipeline != nullptr) {
        TextRecognitionPipeline::PreprocessingConfig cppConfig;
        cppConfig.grayscale = config.grayscale;
        cppConfig.unsharpMasking = config.unsharpMasking;
        cppConfig.binary = config.binary;
        cppConfig.dewarp = config.dewarp;
        cppConfig.resize = config.resize;

        pipeline->preprocessingStep(cppConfig);
    }
}

C_ImageBuffer TextRecognition_getImage(TextRecognitionPipeline* pipeline) {
    C_ImageBuffer buffer = {nullptr, 0};

    if (pipeline == nullptr) {
        return buffer;
    }

    const cv::Mat img = pipeline->getImage();

    if (img.empty()) {
        syslog(LOG_ALERT, "TextRecognition_getEncodedImage: Image is empty!");
        return buffer;
    }

    std::vector<uint8_t> encoded;
    const std::vector params = {cv::IMWRITE_JPEG_QUALITY, 80};

    try {
        cv::imencode(".jpg", img, encoded, params);
    } catch (const std::exception& e) {
        syslog(LOG_ALERT, "Encoding failed: %s", e.what());
        return buffer;
    }

    if (encoded.empty()) return buffer;

    buffer.length = static_cast<int>(encoded.size());
    buffer.imageData = static_cast<uint8_t*>(malloc(buffer.length));

    if (buffer.imageData != nullptr) {
        std::memcpy(buffer.imageData, encoded.data(), buffer.length);
    }
    return buffer;
}

void TextRecognition_freeImage(const C_ImageBuffer imageBuffer) {
    if (imageBuffer.imageData != nullptr) {
        free(imageBuffer.imageData);
    }
}

void TextRecognition_initTesseract(TextRecognitionPipeline* pipeline, const char* filepath) {
    if (pipeline != nullptr) pipeline->initTesseract(filepath);
}

void TextRecognition_textRecognitionStep(TextRecognitionPipeline* pipeline) {
    if (pipeline != nullptr) pipeline->textRecognitionStep();
}

int TextRecognition_initUnigramDictionary(TextRecognitionPipeline* pipeline, const char *filepath) {
    if (pipeline != nullptr) return pipeline->initUnigramDictionary(filepath);
    return -1;
}

int TextRecognition_initBigramDictionary(TextRecognitionPipeline* pipeline, const char *filepath) {
    if (pipeline != nullptr) return pipeline->initBigramDictionary(filepath);
    return -1;
}

void TextRecognition_postprocessingStep(TextRecognitionPipeline* pipeline, const C_PostprocessingConfig config) {
    if (pipeline != nullptr) {
        TextRecognitionPipeline::PostprocessingConfig cppConfig;
        cppConfig.useTopResultFromDictionary = config.useTopResultFromDictionary;
        cppConfig.useContext = config.useContext;

        pipeline->postprocessingStep(cppConfig);
    }
}

int TextRecognition_getResultCount(TextRecognitionPipeline* pipeline) {
    if (pipeline == nullptr) return 0;
    return static_cast<int>(pipeline->getRecognitionResult().size());
}

C_RecognitionResultItem TextRecognition_getResultItem(TextRecognitionPipeline* pipeline, const int index) {
    C_RecognitionResultItem item = {0, 0, 0, 0, nullptr, false};

    if (pipeline != nullptr) {
        auto results = pipeline->getRecognitionResult();
        if (index >= 0 && index < results.size()) {
            const auto& tuple = results[index];
            item.x1 = std::get<0>(tuple);
            item.y1 = std::get<1>(tuple);
            item.x2 = std::get<2>(tuple);
            item.y2 = std::get<3>(tuple);
            item.word = std::get<4>(tuple).c_str();
            item.is_eol = std::get<5>(tuple);
        }
    }
    return item;
}