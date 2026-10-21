# Adaptive Noise Cancellation Using LMS and NLMS

## Overview

This project implements Adaptive Noise Cancellation (ANC) in MATLAB using the Least Mean Squares (LMS) and Normalized Least Mean Squares (NLMS) algorithms. It explores how adaptive filtering can reduce unwanted noise in an audio signal and compares the performance of both algorithms under different signal-to-noise ratio (SNR) conditions.

## Objectives

- Implement LMS and NLMS adaptive filtering algorithms.
- Process clean speech and reference noise signals.
- Compare noisy input signals with the outputs of both algorithms.
- Evaluate signal quality using SNR and SNR improvement.
- Save processed audio and numerical results for analysis.

## Tools and Technologies

- MATLAB
- Digital Signal Processing
- Adaptive Filtering
- Audio Signal Processing

## Implementation Details

The MATLAB script `noise_cancellation.m` performs the following steps:

1. Loads the clean audio and reference noise signals.
2. Converts the signals to mono and resamples them to 16 kHz when required.
3. Normalizes the signals and prepares noise conditions targeting −5 dB and +10 dB SNR.
4. Applies LMS and NLMS adaptive filters using a filter length of 64.
5. Calculates input and output SNR and the corresponding SNR improvement.
6. Saves the processed audio files and exports the results to a CSV file.

## Algorithms

### LMS (Least Mean Squares)

LMS updates the adaptive filter coefficients using the error signal and a fixed step size. Its performance depends on the selected step size and input signal characteristics.

### NLMS (Normalized Least Mean Squares)

NLMS adjusts the step size according to the energy of the reference input, helping control coefficient updates when the input signal power varies.

## Project Structure

```text
DSP_PBL/
├── noise_cancellation.m
├── clean_audio.wav
├── noise.wav
└── ANC_results/
    ├── ANC_results.csv
    ├── noisy_-5dB.wav
    ├── noisy_+10dB.wav
    ├── LMS_-5dB.wav
    ├── LMS_+10dB.wav
    ├── NLMS_-5dB.wav
    └── NLMS_+10dB.wav
```

## How to Run

1. Install MATLAB.
2. Place `noise_cancellation.m`, `clean_audio.wav`, and `noise.wav` in the same working directory.
3. Set MATLAB's Current Folder to the project directory.
4. Run `noise_cancellation.m`.
5. View the generated waveform plots and the SNR comparison table.
6. Find the processed audio files and `ANC_results.csv` in the `ANC_results` folder.

## Results

The project evaluates the input SNR, output SNR, and SNR improvement for LMS and NLMS under two noise conditions. The numerical results are saved in `ANC_results.csv`, and the processed audio files allow listening-based comparisons.

Actual performance depends on the input signals and filter parameters.

## Future Scope

- Add convergence curves and quantitative performance visualizations.
- Compare additional adaptive filtering algorithms.
- Explore different filter lengths and step sizes.
- Extend the implementation to real-time audio processing.
