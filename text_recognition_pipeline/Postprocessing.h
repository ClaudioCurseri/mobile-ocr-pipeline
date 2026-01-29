#ifndef POSTPROCESSING_H
#define POSTPROCESSING_H
#include <string>
#include <tesseract/baseapi.h>

#include "third_party/yams-symspell/include/symspell/symspell.hpp"

class Postprocessing {
public:
    Postprocessing();
    int initUnigramDictionary(const char *filepath);
    int initBigramDictionary(const char *filepath) const;
    std::vector<std::tuple<int, int, int, int, std::string, bool>> postprocessingStep(tesseract::ResultIterator* in) const;
    std::vector<std::tuple<int, int, int, int, std::string, bool>> postprocessingStepWithContext(tesseract::ResultIterator* in) const;
private:
    std::unique_ptr<yams::symspell::SymSpell> symspell;
    std::unique_ptr<yams::symspell::MemoryStore> store;
    std::unique_ptr<yams::symspell::SymSpell> biSymspell;
    std::unique_ptr<yams::symspell::MemoryStore> biStore;
    long long totalUnigramCount;
    std::string replaceWithTopResult(const std::string &word) const;
    std::string replaceWithTopResultAdvanced(const std::string &word) const;
    std::string replaceWithContext(const std::string &previousWord, const std::string &currentWord) const;
};



#endif //POSTPROCESSING_H
