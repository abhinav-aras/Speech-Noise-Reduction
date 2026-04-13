clc;
clear;
close all;
clear sound;

[clean, fs] = audioread('clean_audio.wav');
if size(clean,2) > 1
    clean = mean(clean,2);
end
clean = clean(:);
noise = 0.01 * randn(size(clean));
noisy = clean + noise;

if max(abs(noisy)) > 0
    noisy = noisy / max(abs(noisy));
end

audiowrite('noisy_audio.wav', noisy, fs);
low = 80;
high = 5000;
[b, a] = butter(2, [low high]/(fs/2), 'bandpass');

filtered = filtfilt(b, a, noisy);
filtered = 0.7 * filtered + 0.3 * noisy;
filtered(isnan(filtered)) = 0;
filtered(isinf(filtered)) = 0;

if max(abs(filtered)) > 0
    filtered = filtered / max(abs(filtered));
end

filtered = max(min(filtered, 1), -1);
filtered = filtered(:); 
audiowrite('cleaned_audio.wav', filtered, fs);
t = (0:length(clean)-1)/fs;

figure;
subplot(3,1,1);
plot(t, clean);
title('Clean Speech Signal');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(3,1,2);
plot(t, noisy);
title('Noisy Signal');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(3,1,3);
plot(t, filtered);
title('Filtered (Noise Reduced) Signal');
xlabel('Time (s)'); ylabel('Amplitude');

figure;
subplot(3,1,1);
spectrogram(clean, 256, [], [], fs, 'yaxis');
title('Clean Signal Spectrogram');

subplot(3,1,2);
spectrogram(noisy, 256, [], [], fs, 'yaxis');
title('Noisy Signal Spectrogram');

subplot(3,1,3);
spectrogram(filtered, 256, [], [], fs, 'yaxis');
title('Filtered Signal Spectrogram');

fprintf('\n--- Playing CLEAN (Original) Audio ---\n');
clear sound;
soundsc(clean, fs);
pause(length(clean)/fs + 1);

fprintf('\n--- Playing NOISY Audio ---\n');
clear sound;
soundsc(noisy, fs);
pause(length(noisy)/fs + 1);

fprintf('\n--- Playing FILTERED (Noise Reduced) Audio ---\n');
clear sound;
soundsc(filtered, fs);
pause(length(filtered)/fs + 1);