%% Multi-band Filter Design
% Design Mid and Treble FIR filters to complete the equalizer
clear; clc; close all;

% Load bass filter from Day 1
load('../Day1_FilterDesign/bass_filter.mat');
fprintf('=== Multi-band Equalizer Design ===\n');
fprintf('Bass filter loaded: %d coefficients\n', length(h_bass));

% Audio parameters (consistent with Day 1)
fs = 44100;        % Sample rate
N = 128;           % Filter order (same for all bands)

% Frequency band specifications
fc_low = 250;      % Bass-Mid boundary
fc_high = 4000;    % Mid-Treble boundary

% Normalized frequencies
fc_low_norm = fc_low / (fs/2);
fc_high_norm = fc_high / (fs/2);

fprintf('\nFrequency Bands:\n');
fprintf('Bass:   20 Hz - %d Hz\n', fc_low);
fprintf('Mid:    %d Hz - %d Hz\n', fc_low, fc_high);
fprintf('Treble: %d Hz - 20000 Hz\n', fc_high);

%% Design All Three Filters
fprintf('\n=== Designing Filter Bank ===\n');

% Bass filter (already have from Day 1)
% h_bass = fir1(N, fc_low_norm, 'low', hamming(N+1));

% Mid-band filter (bandpass)
h_mid = fir1(N, [fc_low_norm fc_high_norm], 'bandpass', hamming(N+1));

% Treble filter (highpass)  
h_treble = fir1(N, fc_high_norm, 'high', hamming(N+1));

fprintf('Bass filter:   %d coefficients (loaded)\n', length(h_bass));
fprintf('Mid filter:    %d coefficients (designed)\n', length(h_mid));
fprintf('Treble filter: %d coefficients (designed)\n', length(h_treble));
