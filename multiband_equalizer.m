function [output, bands, clip_db] = multiband_equalizer(input_audio, gains_db, filters, bands)
%MULTIBAND_EQUALIZER  Apply bass / mid / treble gains to audio.
%
%   [output, bands, clip_db] = multiband_equalizer(input_audio, gains_db, filters)
%   [output, ~,     clip_db] = multiband_equalizer([], gains_db, filters, bands)
%
%   input_audio  signal, [samples x channels]  (mono or stereo)
%   gains_db     [bass mid treble] gains in dB (always dB, 0 = unchanged)
%   filters      struct from design_filters(fs)
%   bands        (optional) the 3 band signals returned by an earlier call.
%                Pass them to change the gains WITHOUT filtering again (fast).
%
%   output       equalised audio, same length as the input, delay removed
%   bands        {bass, mid, treble} signals (before gains)
%   clip_db      0 normally; negative if the output had to be lowered to
%                stay inside +/- 1 (so it does not clip)

    % ---- Split into bands (only if not already done) ----
    if nargin < 4 || isempty(bands)
        D  = filters.delay;
        x  = [input_audio; zeros(D, size(input_audio, 2))];   % pad the tail
        hs = {filters.h_bass, filters.h_mid, filters.h_treble};
        bands = cell(1, 3);
        for k = 1:3
            y = fftfilt(hs{k}(:), x);      % fast FIR filtering (per channel)
            bands{k} = y(D + 1 : end, :);  % remove the filter delay
        end
    end

    % ---- Apply gains and add the bands ----
    g = 10 .^ (gains_db(:)' / 20);         % dB -> linear
    output = g(1) * bands{1} + g(2) * bands{2} + g(3) * bands{3};

    % ---- Clip protection ----
    peak = max(abs(output(:)));
    if peak > 1
        output  = output / peak;
        clip_db = 20 * log10(1 / peak);
    else
        clip_db = 0;
    end
end
