#include <filesystem>
#include <fstream>
#include <iostream>
#include <tesseract/baseapi.h>
#include "Postprocessing.h"
#include "Preprocessing.h"
#include "TextRecognition.h"

int main(int argc, char* argv[]) {
    // check for test argument
    auto testOneImage = false;
    long imageNum;
    if (argc > 1) {
        try {
            testOneImage = true;
            imageNum = strtol(argv[1], nullptr, 0);
            std::cout << "Initializing (TEST MODE - will only process one image)..." << std::endl;
        } catch (...) {
            std::cout << "Initializing..." << std::endl;
        }
    }
    // initialize tesseract
    auto *api = new tesseract::TessBaseAPI();
    if (api->Init(nullptr, "eng")) {
        std::cerr << "Could not initialize tesseract." << std::endl;
        return 1;
    }
    api->SetPageSegMode(tesseract::PSM_AUTO);
    // initialize text recognition pipeline
    auto *preprocessing = new Preprocessing();
    auto *textRecognition = new TextRecognition(api);
    // auto *postProcessing = new Postprocessing();
    // ----------run the text recognition pipeline----------
    const std::filesystem::path inputDir = "evaluation/testDataset/input_test/";
    const std::filesystem::path outputDir = "evaluation/testDataset/output_test/";
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
    if (testOneImage) {
        // construct input filepath
        std::ostringstream filenameStream;
        filenameStream << std::setw(5) << std::setfill('0') << imageNum << ".jpg";
        std::string filename = filenameStream.str();
        std::filesystem::path inputPath = inputDir / filename;
        // ensure input file exists
        if (!std::filesystem::exists(inputPath)) {
            std::cerr << "Error: File " << filename << " does not exist." << std::endl;
            return 1;
        }
        // run the pipeline
        auto image = cv::imread(inputPath.string(), cv::IMREAD_COLOR);
        preprocessing->setImage(image);
        preprocessing->preprocessingStep();
        preprocessing->showImage();
    } else {
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
                // run the pipeline
                auto image = cv::imread(inputPath.string(), cv::IMREAD_COLOR);
                preprocessing->setImage(image);
                image = preprocessing->preprocessingStep();
                api->SetImage(image.data, image.cols, image.rows, image.channels(), image.step);
                auto recognitionResult = textRecognition->recognize(image);

                // save results
                if (std::ofstream outFile(outputPath); outFile.is_open()) {
                    outFile << recognitionResult;
                    outFile.close();
                    std::cout << "  > Saved result to: " << outputFilename << std::endl;
                } else {
                    std::cerr << "Error: Could not write to " << outputPath << std::endl;
                }
                imageNum += 1;
            }
        }
    }
    // ----------end of the text recognition pipeline----------
    // free memory
    api->End();
    delete api;
    delete preprocessing;
    delete textRecognition;
    // delete postProcessing;
    std::cout << "Done." << std::endl;
    return 0;
}
