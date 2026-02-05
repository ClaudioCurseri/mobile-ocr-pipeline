#include <filesystem>
#include <fstream>
#include <iostream>
#include "text_recognition_pipeline.h"

/**
 * The main entry point of the text recognition pipeline.
 * This is used to perform a performance evaluation by running the pipeline on a test dataset.
 * Each result is saved in a new text file.
 * @return Whether the execution was successful.
 */
int main() {
    // initialize text recognition pipeline
    auto *textRecognition = new TextRecognitionPipeline();
    // initialize dictionaries
    if (textRecognition->initUnigramDictionary("./assets/frequency_dictionary_en_82_765.txt")) {
        std::cerr << "Could not initialize unigram dictionary." << std::endl;
    }
    if (textRecognition->initBigramDictionary("./assets/frequency_bigramdictionary_en_243_342.txt")) {
        std::cerr << "Could not initialize bigram dictionary." << std::endl;
    }
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
    std::cout << "Running the pipeline..." << std::endl;
    long imageNum = 1;
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
                false,
                false
            };
            // run the pipeline
            textRecognition->initTesseract("./assets/tessdata/");
            textRecognition->setImage(inputPath.string().c_str());
            textRecognition->preprocessingStep(preprocessingConfig);
            textRecognition->textRecognitionStep();
            textRecognition->postprocessingStep(postprocessingConfig);
            auto finalResult = textRecognition->getRecognitionResult();
            // save results
            if (std::ofstream outFile(outputPath); outFile.is_open()) {
                for (const auto& s : finalResult) {
                    // the current word
                    outFile << std::get<4>(s);
                    // ensure correct output format
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
    // free memory
    delete textRecognition;
    std::cout << "Done." << std::endl;
    return 0;
}
