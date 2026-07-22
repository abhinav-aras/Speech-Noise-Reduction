clc; clear; close all; clear sound;

[clean, fs] = audioread('clean_audio.wav');
if size(clean,2) > 1
    clean = mean(clean,2);   % downmix to mono
end
clean = clean(:);

noiseAmp = 0.01;
noise = noiseAmp * randn(size(clean));
noisy = clean + noise;
if max(abs(noisy)) > 0
    noisy = noisy / max(abs(noisy));   % normalize
end
audiowrite('noisy_audio.wav', noisy, fs);

low  = 80;
high = 5000;
[b, a] = butter(2, [low high]/(fs/2), 'bandpass');
filtered = filtfilt(b, a, noisy);

MIX_RAW_SIGNAL = false;
if MIX_RAW_SIGNAL
    filtered = 0.7 * filtered + 0.3 * noisy;
end

filtered(isnan(filtered)) = 0;
filtered(isinf(filtered)) = 0;
if max(abs(filtered)) > 0
    filtered = filtered / max(abs(filtered));
end
filtered = max(min(filtered, 1), -1);
filtered = filtered(:);
audiowrite('cleaned_audio.wav', filtered, fs);

n = min([length(clean), length(noisy), length(filtered)]);
clean_n    = clean(1:n);
noisy_n    = noisy(1:n);
filtered_n = filtered(1:n);

noise_in  = noisy_n    - clean_n;   % error vs. clean = the noise component
noise_out = filtered_n - clean_n;

snr_in  = 10*log10( sum(clean_n.^2) / sum(noise_in.^2)  );
snr_out = 10*log10( sum(clean_n.^2) / sum(noise_out.^2) );
snr_improvement = snr_out - snr_in;

fprintf('\n--- SNR Results ---\n');
fprintf('Input  SNR (noisy vs. clean)    : %.2f dB\n', snr_in);
fprintf('Output SNR (filtered vs. clean) : %.2f dB\n', snr_out);
fprintf('SNR Improvement                 : %.2f dB\n', snr_improvement);

results = struct('snr_in_dB', snr_in, 'snr_out_dB', snr_out, ...
                  'snr_improvement_dB', snr_improvement);
save('snr_results.mat', 'results');
writematrix([snr_in, snr_out, snr_improvement], 'snr_results.csv');

t = (0:n-1)/fs;
figure;
subplot(3,1,1); plot(t, clean_n);    title('Clean Speech Signal');           xlabel('Time (s)'); ylabel('Amplitude');
subplot(3,1,2); plot(t, noisy_n);    title(sprintf('Noisy Signal (SNR = %.1f dB)', snr_in));  xlabel('Time (s)'); ylabel('Amplitude');
subplot(3,1,3); plot(t, filtered_n); title(sprintf('Filtered Signal (SNR = %.1f dB)', snr_out)); xlabel('Time (s)'); ylabel('Amplitude');

figure;
subplot(3,1,1); spectrogram(clean_n, 256, [], [], fs, 'yaxis');    title('Clean Signal Spectrogram');
subplot(3,1,2); spectrogram(noisy_n, 256, [], [], fs, 'yaxis');    title('Noisy Signal Spectrogram');
subplot(3,1,3); spectrogram(filtered_n, 256, [], [], fs, 'yaxis'); title('Filtered Signal Spectrogram');

fprintf('\n--- Playing CLEAN (Original) Audio ---\n');
clear sound; soundsc(clean_n, fs); pause(length(clean_n)/fs + 1);

fprintf('\n--- Playing NOISY Audio ---\n');
clear sound; soundsc(noisy_n, fs); pause(length(noisy_n)/fs + 1);

fprintf('\n--- Playing FILTERED (Noise Reduced) Audio ---\n');
clear sound; soundsc(filtered_n, fs); pause(length(filtered_n)/fs + 1);
