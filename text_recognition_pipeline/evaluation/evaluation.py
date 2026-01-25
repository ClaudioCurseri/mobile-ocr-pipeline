import os
import jiwer
import csv
from typing import List, Tuple

# define paths relative to the script location
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
GT_DIR = os.path.join(BASE_DIR, "testDataset", "input_test_groundtruth")
PRED_DIR = os.path.join(BASE_DIR, "testDataset", "output_test")

REPORT_FILE = os.path.join(BASE_DIR, "evaluation_report.txt")
CSV_FILE = os.path.join(BASE_DIR, "evaluation_details.csv")

def read_text_file(path: str) -> str:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read().strip()
    except FileNotFoundError:
        return ""

def main():
    # check if directories exist
    if not os.path.exists(GT_DIR) or not os.path.exists(PRED_DIR):
        print(f"Error: One of the directories does not exist.\nGT: {GT_DIR}\nPred: {PRED_DIR}")
        return

    # store results: (filename, wer_score, cer_score)
    results: List[Tuple[str, float, float]] = []
    
    # get list of all txt files in the output directory
    pred_files = [f for f in os.listdir(PRED_DIR) if f.endswith(".txt")]
    
    if not pred_files:
        print("No .txt files found in the output folder.")
        return
    
    transformation_cer = jiwer.Compose(
        [
            jiwer.Strip(),
            jiwer.SubstituteWords({"\n\n":"\n"}),
            jiwer.ReduceToListOfListOfChars(),
        ]  
    )

    transformation_wer = jiwer.Compose(
        [
            jiwer.RemoveMultipleSpaces(),
            jiwer.Strip(),
            jiwer.SubstituteWords({"\n\n":"\n"}),
            jiwer.ReduceToListOfListOfWords(),
        ]
    )

    print(f"Processing {len(pred_files)} files...")

    for filename in pred_files:
        pred_path = os.path.join(PRED_DIR, filename)
        gt_path = os.path.join(GT_DIR, filename)

        if not os.path.exists(gt_path):
            print(f"Warning: Ground truth not found for {filename}. Skipping.")
            continue

        hypothesis = read_text_file(pred_path)
        reference = read_text_file(gt_path)

        if len(hypothesis) == 0: continue

        if not reference:
            print(f"Warning: Empty ground truth file {filename}. Skipping.")
            continue

        # calculate WER and CER
        try:
            w = jiwer.wer(reference, hypothesis, hypothesis_transform=transformation_wer)
            c = jiwer.cer(reference, hypothesis, hypothesis_transform=transformation_cer)

            if w >= 1.0: continue

            results.append((filename, w, c))
        except Exception as e:
            print(f"Error processing {filename}: {e}")

    if not results:
        return

    # create csv file with all the metrics per file
    try:
        with open(CSV_FILE, mode='w', newline='', encoding='utf-8') as file:
            writer = csv.writer(file)
            writer.writerow(["Filename", "WER", "CER"])
            for r in results:
                writer.writerow([r[0], f"{r[1]:.4f}", f"{r[2]:.4f}"])
        print(f"CSV saved to: {CSV_FILE}")
    except Exception as e:
        print(f"Error writing CSV: {e}")

    # calculate average WER and CER
    wer_scores = [r[1] for r in results]
    cer_scores = [r[2] for r in results]

    avg_wer = sum(wer_scores) / len(wer_scores)
    avg_cer = sum(cer_scores) / len(cer_scores)

    # find min/max WER/CER
    max_wer_entry = max(results, key=lambda x: x[1])
    min_wer_entry = min(results, key=lambda x: x[1])
    max_cer_entry = max(results, key=lambda x: x[2])
    min_cer_entry = min(results, key=lambda x: x[2])

    # generate report for text file
    report_lines = [
        "Evaluation",
        "=================",
        f"Total Files Evaluated: {len(results)}",
        "",
        f"Average WER: {avg_wer:.4f}",
        f"Average CER: {avg_cer:.4f}",
        "",
        f"Highest WER: {max_wer_entry[1]:.4f} (File: {max_wer_entry[0]})",
        f"Lowest WER:  {min_wer_entry[1]:.4f} (File: {min_wer_entry[0]})",
        "",
        f"Highest CER: {max_cer_entry[2]:.4f} (File: {max_cer_entry[0]})",
        f"Lowest CER:  {min_cer_entry[2]:.4f} (File: {min_cer_entry[0]})"
    ]

    report_content = "\n".join(report_lines)

    # save file
    with open(REPORT_FILE, "w", encoding="utf-8") as f:
        f.write(report_content)

    print("\n" + report_content)
    print(f"\nSummary report saved to: {REPORT_FILE}")

if __name__ == "__main__":
    main()