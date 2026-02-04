# Evaluation

Evaluating the OCR pipeline with a test dataset. The `evaluation.py` script performs a WER and CER evaluation using the ground truth from the test dataset and output data from the OCR pipeline.

## Prerequisites

- Python (tested with version 3.14.2)
- Install the dependencies in `requirements.txt`
- Download the test dataset from https://zenodo.org/records/2572929 and paste the `testDataset` folder in this directory

## Run

- Run the script with `python3 evaluation.py`