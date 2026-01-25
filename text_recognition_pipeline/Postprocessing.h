#ifndef POSTPROCESSING_H
#define POSTPROCESSING_H
#include <string>
#include <tesseract/baseapi.h>

#include "third_party/yams-symspell/include/symspell/symspell.hpp"

class Postprocessing {
public:
    Postprocessing();
    int initDictionary(const char *filepath) const;
    std::vector<std::tuple<int, int, int, int, std::string, bool>> postprocessingStep(tesseract::ResultIterator* in) const;
private:
    std::unique_ptr<yams::symspell::SymSpell> symspell;
    std::unique_ptr<yams::symspell::MemoryStore> store;
    std::string replaceWithTopResult(const std::string &word) const;
    std::string replaceWithTopResultAdvanced(const std::string &word) const;
};



#endif //POSTPROCESSING_H
