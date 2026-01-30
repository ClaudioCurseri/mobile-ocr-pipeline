#include <filesystem>
#include <fstream>
#include <iostream>
#include "TextRecognitionPipeline.h"

int main() {
    long imageNum;
    // initialize text recognition pipeline
    auto *textRecognition = new TextRecognitionPipeline();
    // initialize dictionaries
    if (textRecognition->initUnigramDictionary("./dictionary/frequency_dictionary_en_82_765.txt")) {
        std::cerr << "Could not initialize unigram dictionary." << std::endl;
    }
    if (textRecognition->initUnigramDictionary("./dictionary/most-common-latin-words.txt")) {
        std::cerr << "Could not initialize unigram dictionary." << std::endl;
    }
    if (textRecognition->initBigramDictionary("./dictionary/frequency_bigramdictionary_en_243_342.txt")) {
        std::cerr << "Could not initialize bigram dictionary." << std::endl;
    }
    // ----------run the text recognition pipeline----------
    const std::filesystem::path inputDir = "./../../../evaluation/testDataset/input_test/";
    const std::filesystem::path outputDir = "./../../../evaluation/testDataset/output_test/";
    // ensure input directory exists
    if (!std::filesystem::exists(inputDir)) {
        std::cerr << "Error: Input directory not found at " << std::filesystem::absolute(inputDir) << std::endl;
        return 1;
    }
    // ensure output directory exists
    if (!std::filesystem::exists(outputDir)) {
        std::filesystem::create_directories(outputDir);
    }
    // check whether it should only test one image or run for the whole dataset
    std::cout << "Running the pipeline..." << std::endl;
    imageNum = 1;
        for (const auto& entry : std::filesystem::directory_iterator(inputDir)) {
            if (entry.path().extension() == ".jpg") {
                // construct input filepath
                std::ostringstream filenameStream;
                filenameStream << std::setw(5) << std::setfill('0') << imageNum << ".jpg";
                std::string filename = filenameStream.str();
                std::filesystem::path inputPath = inputDir / filename;

                // construct output filepath
                std::filesystem::path outputFilename = std::filesystem::path(filename).replace_extension(".txt");
                std::filesystem::path outputPath = outputDir / outputFilename;

                // ensure input file exists
                if (!std::filesystem::exists(inputPath)) {
                    std::cerr << "File " << filename << " does not exist. Skipping." << std::endl;
                    continue;
                }
                // pipeline configuration
                auto preprocessingConfig = TextRecognitionPipeline::PreprocessingConfig{
                    true,
                    true,
                    true,
                    true,
                    true
                };
                auto postprocessingConfig = TextRecognitionPipeline::PostprocessingConfig{
                    true,
                    false
                };
                // run the pipeline
                textRecognition->initTesseract();
                textRecognition->setImage(inputPath.string().c_str());
                textRecognition->preprocessingStep(preprocessingConfig);
                textRecognition->textRecognitionStep();
                textRecognition->postprocessingStep(postprocessingConfig);
                auto finalResult = textRecognition->getRecognitionResult();
                // save results
                if (std::ofstream outFile(outputPath); outFile.is_open()) {
                    for (const auto& s : finalResult) {
                        outFile << std::get<4>(s);

                        if (std::get<5>(s)) {
                            outFile << "\n";
                        } else {
                            outFile << " ";
                        }
                    }
                    outFile.close();
                    std::cout << "  > Saved result to: " << outputFilename << std::endl;
                } else {
                    std::cerr << "Error: Could not write to " << outputPath << std::endl;
                }
                imageNum += 1;
            }
        }

    // ----------end of the text recognition pipeline----------
    // free memory
    delete textRecognition;
    std::cout << "Done." << std::endl;
    return 0;
}
