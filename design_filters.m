function filters = design_filters(fs, N, fc_low, fc_high)
%DESIGN_FILTERS  Design the bass / mid / treble FIR filters (one place only).
%
%   filters = design_filters(fs, N, fc_low, fc_high)
%
%   fs       sample rate in Hz                 (default 44100)
%   N        filter order, must be EVEN        (default 1000 -> 1001 taps)
%   fc_low   bass | mid crossover in Hz        (default 250)
%   fc_high  mid | treble crossover in Hz      (default 4000)
%
%   Same design as the original project (fir1 + Hamming window), but with
%   a longer filter so the crossovers are sharp and the three bands add up
%   to a flat response (within about 0.01 dB).
%
%   Needs the Signal Processing Toolbox (fir1, hamming).

    if nargin < 1 || isempty(fs),      fs = 44100;     end
    if nargin < 2 || isempty(N),       N = 1000;       end
    if nargin < 3 || isempty(fc_low),  fc_low = 250;   end
    if nargin < 4 || isempty(fc_high), fc_high = 4000; end

    if mod(N, 2) ~= 0
        error('design_filters:order', 'N must be even (got %d).', N);
    end

    % Keep the crossovers valid for low sample rates
    nyq = fs / 2;
    if fc_high > 0.9 * nyq
        fc_high = 0.9 * nyq;
        warning('design_filters:fc', 'fc_high lowered to %.0f Hz (fs = %d Hz).', fc_high, fs);
    end
    if fc_low > fc_high / 2
        fc_low = fc_high / 2;
        warning('design_filters:fc', 'fc_low lowered to %.0f Hz.', fc_low);
    end

    fc_low_norm  = fc_low  / nyq;      % normalised frequencies (0 .. 1)
    fc_high_norm = fc_high / nyq;

    filters.h_bass   = fir1(N, fc_low_norm,  'low',  hamming(N + 1));
    filters.h_mid    = fir1(N, [fc_low_norm fc_high_norm], 'bandpass', hamming(N + 1));
    filters.h_treble = fir1(N, fc_high_norm, 'high', hamming(N + 1));

    filters.fs      = fs;
    filters.N       = N;
    filters.fc_low  = fc_low;
    filters.fc_high = fc_high;
    filters.delay   = N / 2;           % linear-phase delay in samples
end
