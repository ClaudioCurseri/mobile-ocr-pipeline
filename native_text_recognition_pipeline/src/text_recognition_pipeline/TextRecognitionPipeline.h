#ifndef TEXTRECOGNITIONPIPELINE_H
#define TEXTRECOGNITIONPIPELINE_H
#include <iostream>
#include <fstream>
#include <opencv2/core/mat.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/imgcodecs/imgcodecs.hpp>
#include <tesseract/baseapi.h>
#include "symspell/symspell.hpp"

class TextRecognitionPipeline {
public:
    typedef struct {
        bool grayscale;
        bool unsharpMasking;
        bool binary;
        bool dewarp;
        bool resize;
    } PreprocessingConfig;
    typedef struct {
        bool useTopResultFromDictionary;
        bool useContext;
    } PostprocessingConfig;
    ~TextRecognitionPipeline();
    // preprocessing
    void setImage(const char* imagePath);
    void preprocessingStep(PreprocessingConfig config);
    cv::Mat getImage();
    // text recognition
    void initTesseract();
    void textRecognitionStep();
    // postprocessing
    int initUnigramDictionary(const char *filepath);
    int initBigramDictionary(const char *filepath);
    void postprocessingStep(PostprocessingConfig config);
    std::vector<std::tuple<int, int, int, int, std::string, bool>> getRecognitionResult();
private:
    cv::Mat image;
    cv::Mat internalImage;
    tesseract::TessBaseAPI *api = nullptr;
    tesseract:: ResultIterator *tesseractRecognitionResult = nullptr;
    std::vector<std::tuple<int, int, int, int, std::string, bool>> recognitionResult;
    std::unique_ptr<yams::symspell::SymSpell> symspell;
    std::unique_ptr<yams::symspell::MemoryStore> store;
    std::unique_ptr<yams::symspell::SymSpell> biSymspell;
    std::unique_ptr<yams::symspell::MemoryStore> biStore;
    long long totalUnigramCount = 0;
    // preprocessing
    void convertToGrayscale();
    void unsharpMasking();
    void convertToBinaryImage();
    void resizeImage();
    void dewarpImage();
    // postprocessing
    std::string replaceWithTopResult(const std::string &word) const;
    std::string replaceWithContext(const std::string &previousWord, const std::string &currentWord) const;
};

#endif //TEXTRECOGNITIONPIPELINE_H
