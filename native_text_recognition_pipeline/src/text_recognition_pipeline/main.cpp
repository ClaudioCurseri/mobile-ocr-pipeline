#include <filesystem>
#include <fstream>
#include <iostream>
#include <vector>
#include <future>
#include <mutex>
#include "text_recognition_pipeline.h"

std::mutex log_mutex;

struct Job {
    std::filesystem::path inputPath;
    std::filesystem::path outputPath;
};

void processBatch(const std::vector<Job>& jobs, const int threadId) {
    auto* textRecognition = new TextRecognitionPipeline();

    textRecognition->initUnigramDictionary("./assets/frequency_dictionary_en_82_765.txt");
    textRecognition->initBigramDictionary("./assets/frequency_bigramdictionary_en_243_342.txt");

    textRecognition->initTesseract("./assets/tessdata/");

    constexpr auto preprocessingConfig = TextRecognitionPipeline::PreprocessingConfig{
        true, true, true, true, true
    };
    constexpr auto postprocessingConfig = TextRecognitionPipeline::PostprocessingConfig{
        false, false
    };

    int count = 0;
    for (const auto& job : jobs) {
        textRecognition->setImage(job.inputPath.string().c_str());
        textRecognition->preprocessingStep(preprocessingConfig);
        textRecognition->textRecognitionStep();
        textRecognition->postprocessingStep(postprocessingConfig);

        auto finalResult = textRecognition->getRecognitionResult();

        if (std::ofstream outFile(job.outputPath); outFile.is_open()) {
            for (const auto& s : finalResult) {
                outFile << std::get<4>(s);
                if (std::get<5>(s)) outFile << "\n";
                else outFile << " ";
            }
        }

        count++;
        if (count % 50 == 0) {
            std::lock_guard lock(log_mutex);
            std::cout << "[Thread " << threadId << "] Processed " << count << " images." << std::endl;
        }
    }
    delete textRecognition;
}

/**
 * The main entry point of the text recognition pipeline.
 * This is used to perform a performance evaluation by running the pipeline on a test dataset.
 * Each result is saved in a new text file.
 * @return Whether the execution was successful.
 */
int main() {
    setenv("OMP_THREAD_LIMIT", "1", 1);

    const std::filesystem::path inputDir = "./../../../evaluation/testDataset/input_test/";
    const std::filesystem::path outputDir = "./../../../evaluation/testDataset/output_test/";

    if (!std::filesystem::exists(inputDir)) {
        std::cerr << "Input directory not found." << std::endl;
        return 1;
    }
    std::filesystem::create_directories(outputDir);

    std::vector<Job> allJobs;

    for (const auto& entry : std::filesystem::directory_iterator(inputDir)) {
        if (auto limit = 8470; allJobs.size() >= limit) break;
        if (entry.path().extension() == ".jpg") {
            std::string stem = entry.path().stem().string();
            std::filesystem::path outputFilename = stem + ".txt";
            allJobs.push_back({entry.path(), outputDir / outputFilename});
        }
    }

    unsigned int numThreads = std::thread::hardware_concurrency();

    std::cout << "Found " << allJobs.size() << " images. Processing with " << numThreads << " threads..." << std::endl;

    std::vector<std::vector<Job>> chunks(numThreads);
    for (size_t i = 0; i < allJobs.size(); ++i) {
        chunks[i % numThreads].push_back(allJobs[i]);
    }

    std::vector<std::future<void>> futures;
    for (unsigned int i = 0; i < numThreads; ++i) {
        if (!chunks[i].empty()) {
            futures.push_back(std::async(std::launch::async, processBatch, chunks[i], i));
        }
    }

    for (auto& f : futures) {
        f.get();
    }

    std::cout << "Done." << std::endl;
    return 0;
}