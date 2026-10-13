%% Multi-band Equalizer Function
% Create a complete equalizer system with gain controls
clear; clc; close all;

% Load filter bank
load('multiband_filters.mat');
fprintf('=== Multi-band Equalizer Function ===\n');

%% Define Equalizer Function
function [output, bass_out, mid_out, treble_out] = multiband_equalizer(input_audio, gains)
    % Multi-band equalizer function
    % Inputs:
    %   input_audio - input signal vector
    %   gains - [bass_gain, mid_gain, treble_gain] in dB or linear
    % Outputs:
    %   output - processed audio signal
    %   bass_out, mid_out, treble_out - individual band outputs
    
    % Load filters (assumes multiband_filters.mat is in current directory)
    persistent h_bass h_mid h_treble
    if isempty(h_bass)
        load('multiband_filters.mat', 'h_bass', 'h_mid', 'h_treble');
    end
    
    % Convert dB gains to linear if needed
    if max(abs(gains)) > 5  % Assume dB if large values
        gains_linear = 10.^(gains/20);
    else
        gains_linear = gains;  % Already linear
    end
    
    % Apply filters and gains
    bass_out = gains_linear(1) * filter(h_bass, 1, input_audio);
    mid_out = gains_linear(2) * filter(h_mid, 1, input_audio);
    treble_out = gains_linear(3) * filter(h_treble, 1, input_audio);
    
    % Combine all bands
    output = bass_out + mid_out + treble_out;
end
