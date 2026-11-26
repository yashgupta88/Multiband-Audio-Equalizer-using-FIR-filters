%% STEP 1 - Filter design and analysis (bass, mid, treble)
%  Merges your old bass_filter_design.m and step2_1_multiband_design.m.
%  Designs the 3 FIR filters, checks them, and plots their responses.
%  No audio file needed.

clear; clc; close all;

%% Settings
fs      = 44100;    % sample rate (Hz)
N       = 1000;     % filter order (even). Higher = sharper crossovers
fc_low  = 250;      % bass | mid   crossover (Hz)
fc_high = 4000;     % mid  | treble crossover (Hz)

%% Design (one function, used by every script and by the GUI)
filters  = design_filters(fs, N, fc_low, fc_high);
h_bass   = filters.h_bass;
h_mid    = filters.h_mid;
h_treble = filters.h_treble;

fprintf('=== Filter bank ===\n');
fprintf('Sample rate : %d Hz\n', fs);
fprintf('Order       : %d (%d coefficients per filter)\n', N, N + 1);
fprintf('Bass        : 20 Hz - %d Hz\n', fc_low);
fprintf('Mid         : %d Hz - %d Hz\n', fc_low, fc_high);
fprintf('Treble      : %d Hz - 20000 Hz\n', fc_high);

%% Frequency responses
[H_bass,   f] = freqz(h_bass,   1, 4096, fs);
[H_mid,    ~] = freqz(h_mid,    1, 4096, fs);
[H_treble, ~] = freqz(h_treble, 1, 4096, fs);

% Bass filter values (interpolated at the right frequencies)
bass_db = 20 * log10(abs(H_bass) + eps);
check_f = [100 250 500];
check_db = interp1(f, bass_db, check_f);
fprintf('\n=== Bass filter gain ===\n');
for k = 1:numel(check_f)
    fprintf('At %3d Hz: %7.2f dB\n', check_f(k), check_db(k));
end

% Do the three bands add up to a flat response?
H_sum = H_bass + H_mid + H_treble;
sum_db = 20 * log10(abs(H_sum));
in_range = f >= 20 & f <= 20000;
fprintf('\nBands added together (should be 0 dB):\n');
fprintf('  min %.3f dB, max %.3f dB\n', min(sum_db(in_range)), max(sum_db(in_range)));

%% Plot 1: bass filter in detail
figure('Name', 'Bass filter', 'Position', [100 100 800 600]);
subplot(2, 1, 1);
plot(f, bass_db, 'b', 'LineWidth', 2); hold on;
line([fc_low fc_low], [-100 5], 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1.5);
text(fc_low + 20, -10, sprintf('Cutoff: %d Hz', fc_low), 'Color', 'r');
grid on; xlim([0 1000]); ylim([-100 5]);
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title('Bass filter - magnitude');

subplot(2, 1, 2);
plot(f, unwrap(angle(H_bass)) * 180/pi, 'g', 'LineWidth', 2);
grid on; xlim([0 1000]);
xlabel('Frequency (Hz)'); ylabel('Phase (degrees)');
title('Bass filter - phase (straight line = linear phase)');

%% Plot 2: complete filter bank
figure('Name', 'Complete filter bank', 'Position', [150 80 1100 700]);

subplot(2, 2, 1);
semilogx(f(2:end), 20*log10(abs(H_bass(2:end))   + eps), 'b', 'LineWidth', 2); hold on;
semilogx(f(2:end), 20*log10(abs(H_mid(2:end))    + eps), 'g', 'LineWidth', 2);
semilogx(f(2:end), 20*log10(abs(H_treble(2:end)) + eps), 'r', 'LineWidth', 2);
grid on; xlim([20 20000]); ylim([-90 5]);
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title('Individual responses'); legend('Bass', 'Mid', 'Treble', 'Location', 'southwest');

subplot(2, 2, 2);
semilogx(f(2:end), sum_db(2:end), 'k', 'LineWidth', 2);
grid on; xlim([20 20000]); ylim([-1 1]);
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title('Sum of the three bands (flat = 0 dB)');

subplot(2, 2, 3);
semilogx(f(2:end), unwrap(angle(H_bass(2:end)))   * 180/pi, 'b', 'LineWidth', 1.5); hold on;
semilogx(f(2:end), unwrap(angle(H_mid(2:end)))    * 180/pi, 'g', 'LineWidth', 1.5);
semilogx(f(2:end), unwrap(angle(H_treble(2:end))) * 180/pi, 'r', 'LineWidth', 1.5);
grid on; xlim([20 20000]);
xlabel('Frequency (Hz)'); ylabel('Phase (degrees)');
title('Phase responses'); legend('Bass', 'Mid', 'Treble');

subplot(2, 2, 4);
plot(0:N, h_bass,   'b', 'LineWidth', 1.2); hold on;
plot(0:N, h_mid,    'g', 'LineWidth', 1.2);
plot(0:N, h_treble, 'r', 'LineWidth', 1.2);
grid on; xlabel('Coefficient index'); ylabel('Amplitude');
title('Filter coefficients'); legend('Bass', 'Mid', 'Treble');

%% Test with single tones: which band lets which tone through?
tones = [100 440 2000];           % bass, mid, treble-ish test tones
t = (0:fs-1)' / fs;
fprintf('\n=== Tone test: gain of each band (dB) ===\n');
fprintf('  tone     bass     mid   treble\n');
for k = 1:numel(tones)
    s = sin(2*pi*tones(k)*t);
    [~, b] = multiband_equalizer(s, [0 0 0], filters);
    g = zeros(1, 3);
    for j = 1:3
        seg  = b{j}(10001:end-10000);                 % ignore edge effects
        g(j) = 20*log10(sqrt(mean(seg.^2)) / sqrt(0.5) + 1e-12);
    end
    fprintf('  %4d Hz %7.1f %7.1f %7.1f\n', tones(k), g(1), g(2), g(3));
end

%% Multi-tone signal: bass band keeps only the 100 Hz tone
test_signal = sin(2*pi*100*t) + 0.7*sin(2*pi*440*t) + 0.5*sin(2*pi*2000*t);
[~, b] = multiband_equalizer(test_signal, [0 0 0], filters);
idx = 2001:2500;
figure('Name', 'Bass band of a multi-tone signal', 'Position', [200 100 800 500]);
subplot(2, 1, 1);
plot(t(idx), test_signal(idx)); grid on;
title('Original: 100 Hz + 440 Hz + 2000 Hz'); xlabel('Time (s)'); ylabel('Amplitude');
subplot(2, 1, 2);
plot(t(idx), b{1}(idx)); grid on;
title('Bass band only: mostly the 100 Hz tone'); xlabel('Time (s)'); ylabel('Amplitude');

fprintf('\nStep 1 complete.\n');
