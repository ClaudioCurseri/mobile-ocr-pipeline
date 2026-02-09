# On-Device OCR In Mobile Applications

> Bachelor's Thesis: Development and Evaluation of an On-Device OCR-Pipeline for Text Recognition and Digital Processing of Documents in Mobile Applications

## Project Structure

* `evaluation`: Contains a Python script to evaluate the OCR pipeline.
* `native_text_recognition_pipeline`: Contains a Dart package that binds the native source code. The actual C++ implementation of the text recognition pipeline is inside the `src/` folder.
* `scan_local_app`: Contains a Flutter application compatible with Android and iOS. The app utilizes the native text recognition pipeline for document scanning.

## License Note

This repository is released under the MIT License. See [`LICENSE`](LICENSE) for details.

Additionally, some parts of this project use third party components:

- [Tesseract](https://github.com/tesseract-ocr/tesseract) for text recognition.
- [Leptonica](https://github.com/DanBloomberg/leptonica) library which is used by Tesseract.
- [OpenCV](https://github.com/opencv/opencv) for image processing in the preprocessing step.
> See the [`README`](native_text_recognition_pipeline/tesseract-build/README.md) for more information about the usage of Tesseract, Leptonica and OpenCV in the Flutter application.
- A [C++ port](https://github.com/trvon/yams-symspell) of [SymSpell](https://github.com/wolfgarbe/SymSpell) for OCR error correction in the postprocessing step.
- Word frequency dictionaries provided in the [SymSpell](https://github.com/wolfgarbe/SymSpell) repository:
    - [Google Books Ngram data](http://storage.googleapis.com/books/ngrams/books/datasetsv2.html)   [(License)](https://creativecommons.org/licenses/by/3.0/)
    - [SCOWL - Spell Checker Oriented Word Lists](http://wordlist.aspell.net/)   [(License)](http://wordlist.aspell.net/scowl-readme/)
    - [`More details`](scan_local_app/assets/licenses/dictionaries.txt).
- A test dataset to evaluate the C++ implementation of the OCR pipeline: 
   - Burie, J.-C., Chazalon, J., Coustaty, M., Eskenazi, S., Luqman, M. M., Mehri, M., Nayef, N., OGIER, J.-M., Prum, S., & Rusinol, M. (2015). ICDAR2015 competition on smartphone document capture and OCR (SmartDoc) - Challenge 2 [Data set]. Zenodo. https://doi.org/10.5281/zenodo.2572929