#include "Postprocessing.h"
#include <fstream>
#include <string>
#include <iostream>
#include <sstream>
#include <tesseract/baseapi.h>

Postprocessing::Postprocessing() {
    this->store = std::make_unique<yams::symspell::MemoryStore>(2, 7);
    this->symspell = std::make_unique<yams::symspell::SymSpell>(std::move(this->store), 2, 7);
}

int Postprocessing::initDictionary(const char *filepath) const {
    std::ifstream dictionary(filepath);
    if (!dictionary.is_open()) {
        std::cerr << "Error: Could not open file." << std::endl;
        return -1;
    }
    std::string word;
    long long frequency;
    while (dictionary >> word >> frequency) {
        this->symspell->createDictionaryEntry(word, frequency);
    }
    std::cout << "Initialised dictionary." << std::endl;
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
