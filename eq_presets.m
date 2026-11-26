function [names, gains] = eq_presets()
%EQ_PRESETS  The equaliser presets (defined once, used by scripts and GUI).
%
%   [names, gains] = eq_presets()
%   names  cell array of preset names
%   gains  [number_of_presets x 3] matrix: [bass mid treble] in dB

    names = {'Flat', 'Pop/Rock', 'Vocal', 'V-Shape', 'Bright', 'Bass Boost'};
    gains = [ 0  0  0;
              6 -2  3;
             -3  4  2;
              8 -4  6;
             -6  0  8;
              8  0  0];
end
