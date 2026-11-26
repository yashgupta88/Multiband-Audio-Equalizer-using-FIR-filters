%% STEP 3 - Equalise a real audio file with the presets
%  Merges your old step1_3_audio_processing.m and step2_3_real_audio_multiband.m.
%
%  Put your own WAV file in the AudioFiles folder and set input_file below.
%  If the file does not exist, a synthetic test song is created for you.
%  Results are written to AudioFiles/output/.

clear; clc; close all;

%% Settings
input_file  = 'test_music.wav';   % file inside the AudioFiles folder
max_seconds = 60;                 % only process the first 60 s

%% Folders (work no matter which folder MATLAB is in)
here = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end
audio_dir = fullfile(here, 'AudioFiles');
out_dir   = fullfile(audio_dir, 'output');
if ~exist(audio_dir, 'dir'), mkdir(audio_dir); end
if ~exist(out_dir,   'dir'), mkdir(out_dir);   end
in_path = fullfile(audio_dir, input_file);

%% Create a test song if there is no audio file yet
if ~exist(in_path, 'file')
    fprintf('%s not found - creating a synthetic test song.\n', input_file);
    fs_demo  = 44100;
    t = (0:1/fs_demo:10 - 1/fs_demo)';
    rng(1);
    bass_drum = sin(2*pi*60*t)  .* exp(-mod(t, 1) * 5);          % bass drum
    snare     = sin(2*pi*200*t) .* exp(-mod(t - 0.5, 1) * 8);    % snare
    melody    = sin(2*pi*440*t + sin(2*pi*2*t)) * 0.5;           % melody with vibrato
    harmony   = sin(2*pi*660*t) * 0.3;                           % harmony
    hihat     = 0.3 * [0; diff(randn(numel(t), 1))] .* exp(-mod(t, 0.25) * 60);  % treble content
    test_music = bass_drum + snare + melody + harmony + hihat;
    test_music = test_music / max(abs(test_music)) * 0.8;
    audiowrite(in_path, test_music, fs_demo);
end

%% Load audio
[audio, fs] = audioread(in_path);
fprintf('Loaded %s: %.1f s, %d Hz, %d channel(s)\n', ...
        input_file, size(audio, 1) / fs, fs, size(audio, 2));

audio = audio(1 : min(end, round(max_seconds * fs)), :);   % limit length
if size(audio, 2) > 2, audio = audio(:, 1:2); end          % at most stereo
audio = 0.5 * audio / max(abs(audio(:)));                  % peak 0.5 = headroom for boosts

%% Design filters for THIS file's sample rate and split into bands once
filters = design_filters(fs);
tic;
[~, bands] = multiband_equalizer(audio, [0 0 0], filters);
fprintf('Filtering done in %.2f s\n', toc);

%% Apply every preset
[preset_names, preset_gains] = eq_presets();
processed = cell(numel(preset_names), 1);

fprintf('\n%-12s %6s %6s %6s   %s\n', 'Preset', 'Bass', 'Mid', 'Treble', 'Saved as');
for k = 1:numel(preset_names)
    [y, ~, clip_db] = multiband_equalizer([], preset_gains(k, :), filters, bands);
    processed{k} = y;

    fname = [lower(regexprep(preset_names{k}, '[^A-Za-z0-9]+', '_')) '.wav'];
    audiowrite(fullfile(out_dir, fname), y, fs);

    note = '';
    if clip_db < -0.05, note = sprintf('  (lowered %.1f dB to avoid clipping)', -clip_db); end
    fprintf('%-12s %+5.0f %+6.0f %+6.0f   output/%s%s\n', preset_names{k}, ...
            preset_gains(k, 1), preset_gains(k, 2), preset_gains(k, 3), fname, note);
end
audiowrite(fullfile(out_dir, 'original.wav'), audio, fs);
fprintf('\nSaved %d files in %s\n', numel(preset_names) + 1, out_dir);

%% Plot: spectrum of the original vs each preset
figure('Name', 'EQ presets', 'Position', [100 100 1200 650]);
[P0, fp] = pwelch(mean(audio, 2), hann(4096), 2048, 4096, fs);
for k = 1:numel(preset_names)
    [P1, ~] = pwelch(mean(processed{k}, 2), hann(4096), 2048, 4096, fs);
    subplot(2, 3, k);
    semilogx(fp(2:end), 10*log10(P0(2:end)), 'Color', [0.6 0.6 0.6]); hold on;
    semilogx(fp(2:end), 10*log10(P1(2:end)), 'b', 'LineWidth', 1.4);
    grid on; xlim([20 min(20000, fs/2)]);
    xlabel('Frequency (Hz)'); ylabel('Power (dB)');
    title(sprintf('%s  [%+g %+g %+g dB]', preset_names{k}, preset_gains(k, :)));
    if k == 1, legend('Original', 'Equalised', 'Location', 'southwest'); end
end

%% Listen (optional): remove the % at the start of a line
% sound(audio, fs);              % original
% sound(processed{2}, fs);       % Pop/Rock preset

fprintf('\nStep 3 complete.\n');
