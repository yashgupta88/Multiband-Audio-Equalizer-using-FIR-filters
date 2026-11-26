%% STEP 2 - Equalizer test with a synthetic signal
%  Your old step2_2_equalizer_function.m. The equalizer function now lives in
%  its own file (multiband_equalizer.m) so every script and the GUI share it.

clear; clc; close all;

fs = 44100;
filters = design_filters(fs);

%% Test signal: one tone in each band + a little noise
duration = 5;
t = (0:1/fs:duration-1/fs)';
rng(1);                                        % same noise every run

bass_tone   = sin(2*pi*80*t);                  % 80 Hz   (bass)
mid_tone    = sin(2*pi*1000*t);                % 1 kHz   (mid)
treble_tone = sin(2*pi*8000*t);                % 8 kHz   (treble)
test_signal = 0.3*(bass_tone + mid_tone + treble_tone) + 0.1*randn(size(t));
test_signal = test_signal / max(abs(test_signal)) * 0.5;

fprintf('Test signal: %.1f s with 80 Hz, 1000 Hz and 8000 Hz tones\n', duration);

%% EQ settings to test: [bass mid treble] in dB
eq_settings = [ 0  0  0;      % Flat
                6 -3 -3;      % Bass boost
               -3  6 -3;      % Mid boost
               -3 -3  6;      % Treble boost
                3  0  3;      % V-shape
               -6  0  0];     % Bass cut
setting_names = {'Flat', 'Bass Boost', 'Mid Boost', 'Treble Boost', 'V-Shape', 'Bass Cut'};

%% Process: split into bands ONCE, then just re-mix for each setting
[~, bands] = multiband_equalizer(test_signal, [0 0 0], filters);

processed = zeros(length(test_signal), size(eq_settings, 1));
fprintf('\n=== Testing EQ settings ===\n');
for k = 1:size(eq_settings, 1)
    processed(:, k) = multiband_equalizer([], eq_settings(k, :), filters, bands);
    fprintf('%-13s Bass=%+.0f dB  Mid=%+.0f dB  Treble=%+.0f dB\n', ...
            setting_names{k}, eq_settings(k, 1), eq_settings(k, 2), eq_settings(k, 3));
end

% With all gains at 0 dB the output should equal the input
flat_error = max(abs(processed(:, 1) - test_signal));
fprintf('\nFlat setting: largest difference from the input = %.4f (should be ~0)\n', flat_error);

%% Plots
figure('Name', 'Equalizer settings comparison', 'Position', [100 100 1400 900]);

% Time domain (first 1000 samples) and spectrum of the first 4 settings
for k = 1:4
    subplot(3, 4, k);
    plot(t(1:1000), test_signal(1:1000), 'k--'); hold on;
    plot(t(1:1000), processed(1:1000, k), 'b', 'LineWidth', 1.3);
    grid on; title(setting_names{k});
    xlabel('Time (s)'); ylabel('Amplitude');
    if k == 1, legend('Original', 'Processed'); end

    subplot(3, 4, k + 4);
    [P0, fp] = pwelch(test_signal,     hann(4096), 2048, 4096, fs);
    [P1, ~]  = pwelch(processed(:, k), hann(4096), 2048, 4096, fs);
    semilogx(fp(2:end), 10*log10(P0(2:end)), 'k--'); hold on;
    semilogx(fp(2:end), 10*log10(P1(2:end)), 'b', 'LineWidth', 1.3);
    grid on; xlim([20 20000]);
    title([setting_names{k} ' - spectrum']);
    xlabel('Frequency (Hz)'); ylabel('Power (dB)');
    if k == 1, legend('Original', 'Processed', 'Location', 'southwest'); end
end

% Bar chart of all settings (one group per setting: bass, mid, treble)
subplot(3, 4, 9:12);
bar(eq_settings);
grid on;
set(gca, 'XTickLabel', setting_names);
ylabel('Gain (dB)');
title('Equalizer gain settings');
legend('Bass', 'Mid', 'Treble');

fprintf('\nStep 2 complete.\n');
