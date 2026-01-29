#include "Postprocessing.h"
#include <fstream>
#include <string>
#include <iostream>
#include <sstream>
#include <tesseract/baseapi.h>

Postprocessing::Postprocessing() {
    this->store = std::make_unique<yams::symspell::MemoryStore>(2, 7);
    this->symspell = std::make_unique<yams::symspell::SymSpell>(std::move(this->store), 2, 7);
    this->biStore = std::make_unique<yams::symspell::MemoryStore>(2, 7);
    this->biSymspell = std::make_unique<yams::symspell::SymSpell>(std::move(this->biStore), 2, 7);
}


int Postprocessing::initBigramDictionary(const char *filepath) const {
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

int Postprocessing::initUnigramDictionary(const char *filepath) {
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

std::vector<std::tuple<int, int, int, int, std::string, bool>> Postprocessing::postprocessingStep(tesseract::ResultIterator* in) const {
    constexpr tesseract::PageIteratorLevel level = tesseract::RIL_WORD;
    std::vector<std::tuple<int, int, int, int, std::string, bool>> result;
    if (in != nullptr) {
        do {
            std::string word = in->GetUTF8Text(level);
            word = replaceWithTopResultAdvanced(word);
            int x1, y1, x2, y2;
            in->BoundingBox(level, &x1, &y1, &x2, &y2);
            bool is_eol = in->IsAtFinalElement(tesseract::RIL_TEXTLINE, level);
            result.emplace_back(x1, y1, x2, y2, word, is_eol);
        } while (in->Next(level));
    }
    return result;
}

std::vector<std::tuple<int, int, int, int, std::string, bool>> Postprocessing::postprocessingStepWithContext(tesseract::ResultIterator* in) const {
    constexpr tesseract::PageIteratorLevel level = tesseract::RIL_WORD;
    std::vector<std::tuple<int, int, int, int, std::string, bool>> result;
    if (in != nullptr) {
        std::string previousWord;
        do {
            std::string word = in->GetUTF8Text(level);
            word = replaceWithContext(previousWord, word);
            int x1, y1, x2, y2;
            in->BoundingBox(level, &x1, &y1, &x2, &y2);
            bool is_eol = in->IsAtFinalElement(tesseract::RIL_TEXTLINE, level);
            result.emplace_back(x1, y1, x2, y2, word, is_eol);
            if (is_eol) {
                previousWord = "";
            } else {
                previousWord = word;
            }
        } while (in->Next(level));
    }
    return result;
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

bool containsPunctuationAtStartOrEnd(const std::string &word) {
    return word.starts_with("(") or word.ends_with(")")
    or word.ends_with(".") or word.ends_with("!") or word.ends_with("?")
    or word.ends_with(",") or word.ends_with(";") or word.ends_with(":");
}

// replaces EVERY word with the top result from the dictionary
std::string Postprocessing::replaceWithTopResult(const std::string &word) const {
    std::string replacement = word;
    for (const auto suggestion = this->symspell->lookup(word, yams::symspell::Verbosity::Top); const auto& s : suggestion) {
        if (s.distance == 0) return word;
        replacement = s.term;
        std::cout << "Replaced " << word << " with " << replacement << std::endl;
    }
    return replacement;
}

// replaces every word with the top result from the dictionary ONLY IF the following conditions are met:
// - the word is alphanumeric
// - the word is not a number
// - the word does not contain punctuation symbols at the start or more importantly at the end
// - the word is longer than a given value
// - the word is capitalized
std::string Postprocessing::replaceWithTopResultAdvanced(const std::string &word) const {
    if (isNotAlphanumeric(word) or isNumber(word)
        or containsPunctuationAtStartOrEnd(word) or isEqOrShorterThan(word, 2)
        or std::isupper(word[0])) return word;
    std::string replacement = word;
    for (const auto suggestion = this->symspell->lookup(word, yams::symspell::Verbosity::Top, 1); const auto& s : suggestion) {
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

std::string Postprocessing::replaceWithContext(const std::string &previousWord, const std::string &currentWord) const {
    if (isNotAlphanumeric(currentWord) or isNumber(currentWord)
        or containsPunctuationAtStartOrEnd(currentWord) or isEqOrShorterThan(currentWord, 1)
        or std::isupper(currentWord[0])) return currentWord;

    const auto exactMatch = this->symspell->lookup(currentWord, yams::symspell::Verbosity::Top, 0);

    if (!exactMatch.empty()) {
        return currentWord;
    }

    const auto unigramCandidates = this->symspell->lookup(currentWord, yams::symspell::Verbosity::All, 1);

    if (unigramCandidates.empty()) return currentWord;

    const long long N = this->totalUnigramCount > 0 ? this->totalUnigramCount : 1000000;

    long long previousUnigramCount = 0;
    if (!previousWord.empty()) {
        const auto suggestion = this->symspell->lookup(previousWord, yams::symspell::Verbosity::Top, 0);
        previousUnigramCount = suggestion.empty() ? 0 : suggestion[0].frequency;
    }

    std::vector<ScoredCandidate> candidates;

    for (const auto& candidate : unigramCandidates) {
        constexpr double lambda = 0.8;
        const long long candidateWordCount = candidate.frequency; // C(w_i)
        long long bigramCount = 0;                                // C(w_{i-1}w_i)
        const double pUnigram = static_cast<double>(candidateWordCount) / static_cast<double>(N);

        if (!previousWord.empty()) {
            const auto suggestion = this->biSymspell->lookup(previousWord + " " + currentWord, yams::symspell::Verbosity::Top, 0);
            bigramCount = suggestion.empty() ? 0 : suggestion[0].frequency;
        }

        double pBigram = 0.0;
        if (previousUnigramCount > 0) {
            pBigram = static_cast<double>(bigramCount) / static_cast<double>(previousUnigramCount);
        }

        // Jelinek-Mercer Smoothing
        const double probability = lambda * pBigram + (1 - lambda) * pUnigram;

        candidates.push_back(ScoredCandidate{candidate.term, probability});
    }
    std::ranges::sort(candidates, [](const ScoredCandidate &candidate1, const ScoredCandidate &candidate2) {
        return candidate1.probability > candidate2.probability;
    });

    if (!candidates.empty() && candidates.front().term != currentWord) {
            std::cout << "Context Corrected: " << currentWord << " -> " << candidates.front().term << " | Probability: " << candidates.front().probability << " (Prev: " << previousWord << ")" << std::endl;
    }

    return candidates.empty() ? currentWord : candidates.front().term;
}
