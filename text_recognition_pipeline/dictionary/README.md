# Frequency Dictionaries

## English Unigram Frequency Dictionary

- `frequency_dictionary_en_82_765.txt`
- From the SymSpell repository

## Latin Unigram Frequency Dictionary

- `most-common-latin-words.txt`
- From https://kyle-p-johnson.com/blog/2015/04/23/most-common-greek-latin-words.html

```
tr -cs '[:alnum:]' '\n' < input.txt | tr '[:upper:]' '[:lower:]' | sort | uniq -c | sort -nr | awk '{print $2 " " $1}' > output.txt
```

## English Bigram Frequency Dictionary

- `frequency_bigramdictionary_en_243_342.txt`
- From the SymSpell repository