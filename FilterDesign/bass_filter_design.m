%%  Bass Filter Design for Audio Equalizer
% Clear workspace
clear; clc; close all;

% Audio parameters (from Step 1.1)
fs = 44100;        % Sample rate (44.1 kHz)
N = 128;           % Filter order

% Bass band specification: 20 Hz - 250 Hz
fc_bass = 250;     % Cutoff frequency in Hz
fc_norm = fc_bass / (fs/2);  % Normalized frequency (0 to 1)

fprintf('=== Bass Filter Design ===\n');
fprintf('Sample Rate: %d Hz\n', fs);
fprintf('Filter Order: %d\n', N);
fprintf('Bass Cutoff: %d Hz\n', fc_bass);
fprintf('Normalized Cutoff: %.4f\n', fc_norm);

%% Design FIR Low-pass Filter for Bass
% Using Hamming window (good balance of performance)
h_bass = fir1(N, fc_norm, 'low', hamming(N+1));

fprintf('\n=== Filter Design Complete ===\n');
fprintf('Filter Length: %d coefficients\n', length(h_bass));
fprintf('First 5 coefficients: ');
fprintf('%.6f ', h_bass(1:5));
fprintf('\n');

% Save filter coefficients
save('bass_filter.mat', 'h_bass', 'fs', 'N', 'fc_bass');
