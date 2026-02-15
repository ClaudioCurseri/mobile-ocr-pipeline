#include "text_recognition_pipeline.h"
#include <syslog.h>
#include <regex>

TextRecognitionPipeline::~TextRecognitionPipeline() {
    this->api->End();
}


void TextRecognitionPipeline::preprocessingStep(const PreprocessingConfig config) {
    if (config.grayscale) this->convertToGrayscale();
    if (config.dewarp) this->dewarpImage();
    if (config.unsharpMasking) this->unsharpMasking();
    if (config.binary) this->convertToBinaryImage();
    if (config.resize) this->resizeImage();
    this->image = this->internalImage.clone();
    this->api->SetImage(this->internalImage.data, this->internalImage.cols, this->internalImage.rows, this->internalImage.channels(), this->internalImage.step);
}

void TextRecognitionPipeline::setImage(const char* imagePath) {
    const auto image = cv::imread(imagePath, cv::IMREAD_COLOR);
    if (image.cols != 3096 && image.rows != 4128) {
        cv::resize(image, this->image, cv::Size(3096, 4128));
    } else {
        this->image = image.clone();
    }
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
    // illumination correction
    cv::Mat downscaled, background;
    constexpr double scaleRatio = 0.25;
    cv::resize(this->internalImage, downscaled, cv::Size(), scaleRatio, scaleRatio);
    const cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(25, 25));
    cv::morphologyEx(downscaled, background, cv::MORPH_CLOSE, kernel);
    cv::resize(background, background, this->internalImage.size());
    cv::divide(this->internalImage, background, this->internalImage, 255, -1);

    // denoising
    cv::GaussianBlur(this->internalImage, this->internalImage, cv::Size(3, 3), 0);

    cv::adaptiveThreshold(this->internalImage, this->internalImage,
                      255,
                      cv::ADAPTIVE_THRESH_GAUSSIAN_C,
                      cv::THRESH_BINARY,
                      81,
                      15);

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

    // denoising
    cv::GaussianBlur(gray, gray, cv::Size(7, 7), 0);

    // edge detection
    cv::Mat edged;
    cv::Canny(gray, edged, 75, 200);

    // edge detection was too strict and made the picture mostly black?
    // -> then try again with lower thresholds and the original grayscale image
    if (cv::countNonZero(edged) < 200000) {
        cv::Canny(gray, edged, 25, 75);
    }

    // dilation -> all structures grow, increases chance of finding the document contours
    cv::Mat dilated;
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(5, 7));
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
        if ( area < imageArea * 0.25) {
            continue;
        }

        double perimeter = cv::arcLength(contour, true);
        std::vector<cv::Point> approx;
        // try to find four contours
        for (double epsilon = 0.01; epsilon <= 0.05; epsilon += 0.01) {
            cv::approxPolyDP(contour, approx, epsilon * perimeter, true);

            if (approx.size() == 4) {
                    documentContour = approx;
                    found = true;
                    goto end_search;
            }
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
    if (api->Init(filepath, "eng+lat", tesseract::OEM_LSTM_ONLY)) {
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
            const auto confidence = this->tesseractRecognitionResult->Confidence(level);
            if (confidence < 25 && word.length() < 3) continue;
            if (config.useTopResultFromDictionary && !config.useContext) word = replaceWithTopResult(word, confidence);
            if (config.useContext) word = replaceWithContext(previousWord, word, confidence);
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

bool isNumber(const std::string &word) {
    return std::ranges::any_of(word, isdigit);
}

std::string cleanWordForLookup(std::string text) {
    // remove punctuation
    std::erase_if(text, [](const char c) { return std::ispunct(c); });
    // to lowercase
    std::ranges::transform(text, text.begin(),
                           [](unsigned char c){ return std::tolower(c); });
    return text;
}

// helper struct to separate word from leading and trailing punctuation
struct TokenParts {
    std::string prefix;
    std::string word;
    std::string suffix;
};

// returns the word as a TokenParts struct
TokenParts extractParts(const std::string& text) {
    // regex: (non-alnum prefix) (alnum word) (non-alnum suffix)
    const std::regex re(R"(^([^a-zA-Z0-9]*)([a-zA-Z0-9]+)([^a-zA-Z0-9]*)$)");
    if (std::smatch match; std::regex_search(text, match, re)) {
        return {match[1].str(), match[2].str(), match[3].str()};
    }
    return {"", text, ""};
}

// detects case and applies it to the replacement
std::string matchCase(const std::string& original, std::string replacement) {
    if (original.empty()) return replacement;

    const bool isAllUpper = std::ranges::all_of(original, [](unsigned char c){ return std::isupper(c) || !std::isalpha(c); });
    const bool isFirstUpper = std::isupper(original[0]);

    if (isAllUpper) {
        std::ranges::transform(replacement, replacement.begin(), toupper);
    } else if (isFirstUpper) {
        if (!replacement.empty()) replacement[0] = std::toupper(replacement[0]);
    }
    return replacement;
}

// replaces every word with the top result from the assets ONLY IF the following conditions are met:
// - the word has a confidence lower than 75
// - the word is not a number or empty
// - the word is longer than a given value
std::string TextRecognitionPipeline::replaceWithTopResult(const std::string &word, float confidence) const {
    // only replace words with lower confidence
    if (confidence > 75.0f) {
        return word;
    }

    TokenParts parts = extractParts(word);

    // skip numbers or very short tokens
    if (parts.word.empty() || isNumber(parts.word) || parts.word.length() < 2) {
        return word;
    }

    // transform search key to lowercase
    std::string searchKey = parts.word;
    std::ranges::transform(searchKey, searchKey.begin(), [](const unsigned char c){ return std::tolower(c); });

    // edit distance
    int maxDist = 1;

    auto suggestions = this->symspell->lookup(searchKey, yams::symspell::Verbosity::All, maxDist);

    if (suggestions.empty()) {
        return word;
    }

    // sort by edit distance, then by frequency
    std::ranges::sort(suggestions, [](const auto& a, const auto& b) {
        if (a.distance != b.distance) {
            return a.distance < b.distance;
        }
        return a.frequency > b.frequency;
    });

    const auto& bestMatch = suggestions[0];

    // return result
    if (bestMatch.distance == 0) {
        return word;
    }

    std::string correctedWord = matchCase(parts.word, bestMatch.term);
    std::string finalResult = parts.prefix + correctedWord + parts.suffix;

    if (finalResult != word) {
        std::cout << "Replaced " << word << " with " << finalResult
                  << " (Conf: " << confidence << ", Dist: " << bestMatch.distance << ")" << std::endl;
    }

    return finalResult;
}

struct ScoredCandidate {
    std::string term;
    double probability;
    int distance;
};

std::string TextRecognitionPipeline::replaceWithContext(const std::string &previousWord, const std::string &currentWord, float confidence) const {
    // only replace words with lower confidence
    if (confidence > 75.0f) {
        return currentWord;
    }

    TokenParts parts = extractParts(currentWord);

    // skip numbers or very short tokens
    if (parts.word.empty() || isNumber(parts.word) || parts.word.length() < 2) {
        return currentWord;
    }

    // transform search key to lowercase
    std::string currentLowercase = parts.word;
    std::ranges::transform(currentLowercase, currentLowercase.begin(), [](const unsigned char c){ return std::tolower(c); });

    // unigrams within max edit distance
    int maxDist = 1;
    auto unigramCandidates = this->symspell->lookup(currentLowercase, yams::symspell::Verbosity::All, maxDist);

    if (unigramCandidates.empty()) return currentWord;

    std::string cleanPrev = cleanWordForLookup(previousWord);
    long long previousUnigramCount = 0;
    bool hasValidContext = false;

    if (!cleanPrev.empty()) {
        const auto suggestion = this->symspell->lookup(cleanPrev, yams::symspell::Verbosity::Top, 0);
        if (!suggestion.empty()) {
            previousUnigramCount = suggestion[0].frequency;
            hasValidContext = true;
        }
    }

    const long long N = this->totalUnigramCount > 0 ? this->totalUnigramCount : 1000000;
    std::vector<ScoredCandidate> candidates;

    // scoring
    for (const auto& candidate : unigramCandidates) {

        double score = 0.0;
        bool foundBigram = false;

        if (hasValidContext && previousUnigramCount > 0) {
            std::string bigramKey = cleanPrev + " " + candidate.term;
            const auto suggestion = this->biSymspell->lookup(bigramKey, yams::symspell::Verbosity::Top, 0);
            if (!suggestion.empty()) {
                long long bigramCount = suggestion[0].frequency;
                // MLE
                score = static_cast<double>(bigramCount) / static_cast<double>(previousUnigramCount);
                foundBigram = true;
            }
        }
        // stupid backoff
        if (!foundBigram) {
            double pUnigram = static_cast<double>(candidate.frequency) / static_cast<double>(N);
            score = 0.4 * pUnigram;
        }
        candidates.push_back(ScoredCandidate{candidate.term, score, candidate.distance});
    }

    // sort descending by score
    std::ranges::sort(candidates, [](const ScoredCandidate &a, const ScoredCandidate &b) {
        if (a.distance != b.distance) {
            return a.distance < b.distance;
        }
        return a.probability > b.probability;
    });

    if (candidates.empty()) return currentWord;
    const auto& bestCandidate = candidates.front();

    if (bestCandidate.term == currentLowercase) {
        return currentWord;
    }

    std::string correctedWord = matchCase(parts.word, bestCandidate.term);
    auto finalResult = parts.prefix + correctedWord + parts.suffix;

    std::cout << "Replaced " << currentWord << " with " << finalResult
                  << " | Conf: " << confidence
                  << " | Context: [" << cleanPrev << "]"
                  << " | Score: " << bestCandidate.probability << std::endl;

    return finalResult;
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