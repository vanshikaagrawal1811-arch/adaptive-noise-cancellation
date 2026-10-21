
clc;
clear;
close all;

%% 1. SETTINGS
Fs = 16000;
targetSNRs = [-5 10];
M = 64;

muLMS = 0.005;
muNLMS = 0.5;
epsilon = 1e-8;

maxDuration = 10;
outFolder = 'ANC_results';

if ~exist(outFolder, 'dir')
    mkdir(outFolder);
end

%% 2. LOAD AUDIO
[voice, fs1] = audioread('clean_audio.wav');
[noise, fs2] = audioread('noise.wav');

% Convert to mono
voice = mean(voice, 2);
noise = mean(noise, 2);

% Resample to 16 kHz
if fs1 ~= Fs
    voice = resample(voice, Fs, fs1);
end

if fs2 ~= Fs
    noise = resample(noise, Fs, fs2);
end

% Use maximum 10 seconds
N = min(length(voice), maxDuration * Fs);
voice = voice(1:N);

% Check and repeat noise if necessary
if isempty(noise)
    error('noise.wav is empty.');
end

if length(noise) < N
    noise = repmat(noise, ceil(N / length(noise)), 1);
end

noise = noise(1:N);

% Normalize speech
voice = voice - mean(voice);
voicePeak = max(abs(voice));

if voicePeak < 1e-8
    error('Speech file is silent.');
end
voice = 0.8 * voice / voicePeak;

% Normalize reference noise
noise = noise - mean(noise);
noiseRMS = sqrt(mean(noise.^2));

if noiseRMS < 1e-8
    error('Noise file is silent.');
end

noise = noise / noiseRMS;

%% 3. CREATE NOISE AT MICROPHONE
primaryNoise = filter([0.8 0.2 0.08], 1, noise);

% Normalize filtered noise
primaryNoiseRMS = sqrt(mean(primaryNoise.^2));
primaryNoise = primaryNoise / primaryNoiseRMS;

%% 4. INITIALIZE RESULTS
numConditions = length(targetSNRs);

inputSNR = zeros(numConditions, 1);
lmsSNR = zeros(numConditions, 1);
nlmsSNR = zeros(numConditions, 1);

lmsImprove = zeros(numConditions, 1);
nlmsImprove = zeros(numConditions, 1);

t = (0:N-1) / Fs;

%% 5. PROCESS BOTH NOISE LEVELS
for k = 1:numConditions

    % Scale noise to achieve the target input SNR
    scale = sqrt(mean(voice.^2)) / ...
        (sqrt(mean(primaryNoise.^2)) * ...
        10^(targetSNRs(k) / 20));

    noisy = voice + scale * primaryNoise;

    % Apply LMS and NLMS noise cancellation
    lms = runANC(noisy, noise, M, muLMS, false, epsilon);
    nlms = runANC(noisy, noise, M, muNLMS, true, epsilon);

    % Ignore initial adaptation samples for SNR evaluation
    start = min(4 * M, floor(N / 2)) + 1;
    idx = start:N;

    % Calculate measured SNR
    inputSNR(k) = calcSNR(voice(idx), noisy(idx));
    lmsSNR(k) = calcSNR(voice(idx), lms(idx));
    nlmsSNR(k) = calcSNR(voice(idx), nlms(idx));

    % Calculate SNR improvement
    lmsImprove(k) = lmsSNR(k) - inputSNR(k);
    nlmsImprove(k) = nlmsSNR(k) - inputSNR(k);

    % Apply the same gain to all audio files
    peak = max([max(abs(noisy)), ...
                max(abs(lms)), ...
                max(abs(nlms))]);

    gain = min(1, 0.99 / (peak + eps));

    % Create filenames using measured input SNR
    tag = sprintf('%+ddB', round(inputSNR(k)));

    % Save audio files
    audiowrite(fullfile(outFolder, ['noisy_' tag '.wav']), ...
        gain * noisy, Fs);

    audiowrite(fullfile(outFolder, ['LMS_' tag '.wav']), ...
        gain * lms, Fs);

    audiowrite(fullfile(outFolder, ['NLMS_' tag '.wav']), ...
        gain * nlms, Fs);

    % Plot waveforms: first 0.25 seconds
    figure(k);

    subplot(3, 1, 1);
    plot(t, noisy);
    xlim([0 min(0.25, t(end))]);
    title(sprintf('Noisy Input (Target SNR: %d dB)', ...
        targetSNRs(k)));
    ylabel('Amplitude');
    grid on;

    subplot(3, 1, 2);
    plot(t, lms);
    xlim([0 min(0.25, t(end))]);
    title('LMS Output');
    ylabel('Amplitude');
    grid on;

    subplot(3, 1, 3);
    plot(t, nlms);
    xlim([0 min(0.25, t(end))]);
    title('NLMS Output');
    xlabel('Time (seconds)');
    ylabel('Amplitude');
    grid on;

end

%% 6. DISPLAY AND SAVE RESULTS
Results = table(inputSNR, lmsSNR, nlmsSNR, ...
    lmsImprove, nlmsImprove, ...
    'VariableNames', {'InputSNR_dB', ...
    'LMS_SNR_dB', 'NLMS_SNR_dB', ...
    'LMS_Improvement_dB', 'NLMS_Improvement_dB'});

disp(Results);

writetable(Results, fullfile(outFolder, 'ANC_results.csv'));

fprintf('Processing complete!\n');
fprintf('Audio files, plots (when saved manually), and CSV results are in: %s\n', ...
    outFolder);

%% 7. LMS / NLMS ADAPTIVE NOISE CANCELLATION FUNCTION
function output = runANC(primary, reference, M, mu, useNLMS, epsilon)

    N = min(length(primary), length(reference));

    primary = primary(1:N);
    reference = reference(1:N);

    % Initialize filter weights and reference buffer
    w = zeros(M, 1);
    buffer = zeros(M, 1);
    output = zeros(N, 1);

    for n = 1:N
        % Update reference signal buffer
        buffer = [reference(n); buffer(1:end-1)];
        % Estimate noise
        estimatedNoise = w' * buffer;
        % Subtract estimated noise from primary input
        output(n) = primary(n) - estimatedNoise;
        % Calculate adaptive step size
        if useNLMS
            step = mu / (epsilon + buffer' * buffer);
        else
            step = mu;
        end
        % Update adaptive filter weights
        w = w + step * output(n) * buffer;
    end
end

%% 8. SNR CALCULATION FUNCTION
function snrValue = calcSNR(clean, test)
    errorSignal = test - clean;
    snrValue = 10 * log10( ...
        sum(clean.^2) / (sum(errorSignal.^2) + eps));

end