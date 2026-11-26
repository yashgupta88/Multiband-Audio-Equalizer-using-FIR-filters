%% Audio Equalizer GUI  (3-band FIR equalizer)
%  Your old step3_2_audio_functions.m / complete_audio_equalizer_gui.m, fixed
%  and merged into ONE file.
%
%  Run it by typing   equalizer_gui   in the Command Window.
%  All other .m files of this project must be in the same folder.
function equalizer_gui()
    % Filters for the default sample rate (so the response curve can be drawn)
    filters0 = design_filters(44100);

    % Create the window
    fig = createCompleteGUI(filters0);

    % Initial state (everything lives in fig.UserData)
    fig.UserData.audioData      = [];          % original audio
    fig.UserData.processedAudio = [];          % equalised audio
    fig.UserData.bands          = [];          % bass/mid/treble signals (split once)
    fig.UserData.filters        = filters0;
    fig.UserData.fs             = 44100;
    fig.UserData.gains          = [0 0 0];     % [bass mid treble] in dB
    fig.UserData.player         = [];
    fig.UserData.infoBase       = '';

    updateVisualization(fig);

    fprintf('=== Audio Equalizer GUI ready ===\n');
    fprintf('Load an audio file or the Handel sample, then move the sliders.\n');
end

%% ======================= Building the window =======================

function fig = createCompleteGUI(filters0)
    fig = uifigure('Name', 'Audio Equalizer - Complete', 'Position', [100 50 920 750]);
    fig.Color = [0.15 0.15 0.15];
    fig.CloseRequestFcn = @(~, ~) closeApp(fig);

    uilabel(fig, 'Position', [310 710 300 25], 'Text', 'Audio Equalizer v1.0', ...
        'FontSize', 20, 'FontWeight', 'bold', 'FontColor', 'white', ...
        'HorizontalAlignment', 'center');

    audioPanel = uipanel(fig, 'Position', [20 500 880 140], ...
        'Title', 'Audio Controls', 'FontSize', 14, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.2 0.2 0.2], 'ForegroundColor', 'white');

    eqPanel = uipanel(fig, 'Position', [20 280 880 210], ...
        'Title', 'Equalizer Controls', 'FontSize', 14, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.2 0.2 0.2], 'ForegroundColor', 'white');

    vizPanel = uipanel(fig, 'Position', [20 20 880 250], ...
        'Title', 'Audio Visualization', 'FontSize', 14, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.2 0.2 0.2], 'ForegroundColor', 'white');

    createAudioControls(audioPanel, fig);
    createEQControls(eqPanel, fig, filters0);
    createVisualization(vizPanel, fig);
end

function createAudioControls(panel, fig)
    uibutton(panel, 'Position', [20 80 120 35], 'Text', 'Load Audio', ...
        'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [0.3 0.6 0.9], ...
        'ButtonPushedFcn', @(~, ~) loadAudioFile(fig));

    playOrigBtn = uibutton(panel, 'Position', [160 80 100 35], 'Text', 'Play Original', ...
        'FontSize', 11, 'BackgroundColor', [0.2 0.8 0.2], 'Enable', 'off', ...
        'ButtonPushedFcn', @(~, ~) playAudio(fig, false));

    playEQBtn = uibutton(panel, 'Position', [280 80 100 35], 'Text', 'Play EQ', ...
        'FontSize', 11, 'BackgroundColor', [0.8 0.6 0.2], 'Enable', 'off', ...
        'ButtonPushedFcn', @(~, ~) playAudio(fig, true));

    stopBtn = uibutton(panel, 'Position', [400 80 80 35], 'Text', 'Stop', ...
        'FontSize', 11, 'BackgroundColor', [0.8 0.2 0.2], 'Enable', 'off', ...
        'ButtonPushedFcn', @(~, ~) stopAudio(fig));

    saveBtn = uibutton(panel, 'Position', [500 80 120 35], 'Text', 'Save EQ Audio', ...
        'FontSize', 11, 'BackgroundColor', [0.8 0.2 0.6], 'Enable', 'off', ...
        'ButtonPushedFcn', @(~, ~) saveProcessedAudio(fig));

    uibutton(panel, 'Position', [650 80 100 35], 'Text', 'Load Handel', ...
        'FontSize', 10, 'BackgroundColor', [0.5 0.5 0.8], ...
        'ButtonPushedFcn', @(~, ~) loadSampleAudio(fig));

    infoLabel = uilabel(panel, 'Position', [20 40 840 25], 'Text', 'No audio loaded', ...
        'FontSize', 12, 'FontColor', 'white');

    fig.UserData.playOrigBtn = playOrigBtn;
    fig.UserData.playEQBtn   = playEQBtn;
    fig.UserData.stopBtn     = stopBtn;
    fig.UserData.saveBtn     = saveBtn;
    fig.UserData.infoLabel   = infoLabel;
end

function createEQControls(panel, fig, filters0)
    names   = {'BASS', 'MID', 'TREBLE'};
    colors  = {'cyan', 'yellow', 'magenta'};
    ranges  = {sprintf('20-%d Hz', filters0.fc_low), ...
               sprintf('%d-%d Hz', filters0.fc_low, filters0.fc_high), ...
               sprintf('%d-20000 Hz', filters0.fc_high)};
    centers = [110 280 450];                 % x-centre of each band's controls

    sliders    = gobjects(1, 3);
    gainLabels = gobjects(1, 3);

    for b = 1:3
        cx = centers(b);
        uilabel(panel, 'Position', [cx-30 170 60 20], 'Text', names{b}, ...
            'FontSize', 14, 'FontWeight', 'bold', 'FontColor', colors{b}, ...
            'HorizontalAlignment', 'center');
        uilabel(panel, 'Position', [cx-50 150 100 20], 'Text', ranges{b}, ...
            'FontSize', 10, 'FontColor', 'white', 'HorizontalAlignment', 'center');

        sliders(b) = uislider(panel, 'Position', [cx-60 130 120 3], ...
            'Limits', [-12 12], 'Value', 0, 'MajorTicks', [-12 -6 0 6 12], ...
            'FontColor', 'white');
        sliders(b).ValueChangedFcn = @(s, ~) updateEQ(fig, b, s.Value);

        gainLabels(b) = uilabel(panel, 'Position', [cx-35 110 70 20], 'Text', '+0.0 dB', ...
            'FontSize', 11, 'FontWeight', 'bold', 'FontColor', 'white', ...
            'HorizontalAlignment', 'center');
    end

    uilabel(panel, 'Position', [580 170 100 20], 'Text', 'EQ Presets:', ...
        'FontSize', 12, 'FontWeight', 'bold', 'FontColor', 'white');

    [presetNames, ~] = eq_presets();
    presetDropdown = uidropdown(panel, 'Position', [580 140 150 25], ...
        'Items', [{'Custom'} presetNames], 'Value', 'Flat', 'FontSize', 11, ...
        'ValueChangedFcn', @(d, ~) applyPreset(fig, d.Value));

    uibutton(panel, 'Position', [750 140 80 25], 'Text', 'Reset', ...
        'FontSize', 11, 'BackgroundColor', [0.6 0.6 0.6], ...
        'ButtonPushedFcn', @(~, ~) resetEQ(fig));

    fig.UserData.sliders        = sliders;
    fig.UserData.gainLabels     = gainLabels;
    fig.UserData.presetDropdown = presetDropdown;
end

function createVisualization(panel, fig)
    ax = uiaxes(panel, 'Position', [30 20 820 200]);
    ax.BackgroundColor = [0.2 0.2 0.2];
    ax.Color     = [0.1 0.1 0.1];
    ax.XColor    = 'white';
    ax.YColor    = 'white';
    ax.GridColor = [0.6 0.6 0.6];
    ax.XScale    = 'log';
    ax.XLim      = [20 20000];
    ax.YLim      = [-15 15];
    ax.XLabel.String = 'Frequency (Hz)';
    ax.YLabel.String = 'Gain (dB)';
    ax.Title.String  = 'EQ frequency response (the filter that is really applied)';
    ax.Title.Color   = 'white';
    ax.Title.FontSize = 14;
    grid(ax, 'on');
    fig.UserData.eqAxes = ax;
end

%% ========================= Loading audio ===========================

function loadAudioFile(fig)
    [filename, pathname] = uigetfile({'*.wav;*.flac;*.mp3;*.m4a;*.ogg', 'Audio Files'}, ...
        'Select Audio File');
    figure(fig);                                   % bring the window back to the front
    if isequal(filename, 0), return; end
    try
        [audioData, fs] = audioread(fullfile(pathname, filename));
        loadSignal(fig, audioData, fs, filename);
    catch ME
        uialert(fig, sprintf('Error loading audio: %s', ME.message), 'Error');
    end
end

function loadSampleAudio(fig)
    try
        S = load('handel', 'y', 'Fs');             % built-in MATLAB sample (8192 Hz)
        y = resample(S.y, 44100, S.Fs);            % convert to 44.1 kHz
        loadSignal(fig, y, 44100, 'Handel sample');
    catch ME
        uialert(fig, sprintf('Error loading sample audio: %s', ME.message), 'Error');
    end
end

function loadSignal(fig, audioData, fs, label)
    % ONE place that prepares any audio (used by both load buttons)
    stopAudio(fig);

    dlg = uiprogressdlg(fig, 'Title', 'Equalizer', ...
        'Message', 'Filtering audio...', 'Indeterminate', 'on');
    cleanup = onCleanup(@() delete(dlg));          %#ok<NASGU>

    % Limit length and channels
    maxSeconds = 60;
    maxN    = round(maxSeconds * fs);
    trimmed = size(audioData, 1) > maxN;
    audioData = audioData(1 : min(end, maxN), :);
    if size(audioData, 2) > 2, audioData = audioData(:, 1:2); end

    % Normalise to a peak of 0.5 so boosts have headroom
    peak = max(abs(audioData(:)));
    if peak > 0, audioData = 0.5 * audioData / peak; end

    % Design filters for THIS file's sample rate and split into bands once
    filters = design_filters(fs);
    [~, bands] = multiband_equalizer(audioData, [0 0 0], filters);

    fig.UserData.audioData = audioData;
    fig.UserData.fs        = fs;
    fig.UserData.filters   = filters;
    fig.UserData.bands     = bands;

    info = sprintf('Loaded: %s  |  %.1f s  |  %d Hz  |  %d channel(s)', ...
        label, size(audioData, 1) / fs, fs, size(audioData, 2));
    if trimmed
        info = sprintf('%s  |  first %d s only', info, maxSeconds);
    end
    fig.UserData.infoBase = info;

    set([fig.UserData.playOrigBtn, fig.UserData.playEQBtn, ...
         fig.UserData.stopBtn, fig.UserData.saveBtn], 'Enable', 'on');

    processAudioWithEQ(fig);
    updateVisualization(fig);
end

%% ======================== Equalizer controls =======================

function updateEQ(fig, band, value)
    % band: 1 = bass, 2 = mid, 3 = treble
    fig.UserData.gains(band) = value;
    fig.UserData.gainLabels(band).Text = sprintf('%+.1f dB', value);
    fig.UserData.presetDropdown.Value = 'Custom';

    processAudioWithEQ(fig);
    updateVisualization(fig);
end

function setGains(fig, gains)
    % ONE place that sets sliders, labels and gains (used by presets and reset)
    fig.UserData.gains = gains;
    for b = 1:3
        fig.UserData.sliders(b).Value = gains(b);
        fig.UserData.gainLabels(b).Text = sprintf('%+.1f dB', gains(b));
    end
    processAudioWithEQ(fig);
    updateVisualization(fig);
end

function applyPreset(fig, presetName)
    [names, gains] = eq_presets();
    idx = find(strcmp(names, presetName), 1);
    if isempty(idx), return; end                   % 'Custom': nothing to apply
    setGains(fig, gains(idx, :));
end

function resetEQ(fig)
    fig.UserData.presetDropdown.Value = 'Flat';
    setGains(fig, [0 0 0]);
end

function processAudioWithEQ(fig)
    ud = fig.UserData;
    if isempty(ud.bands), return; end

    % Bands are already split, so this is just a quick re-mix
    [y, ~, clip_db] = multiband_equalizer([], ud.gains, ud.filters, ud.bands);
    fig.UserData.processedAudio = y;

    info = ud.infoBase;
    if clip_db < -0.05
        info = sprintf('%s  |  EQ output lowered %.1f dB to avoid clipping', info, -clip_db);
    end
    ud.infoLabel.Text = info;
end

function updateVisualization(fig)
    ud = fig.UserData;
    ax = ud.eqAxes;

    % Real frequency response of the three filters with the current gains
    g = 10 .^ (ud.gains / 20);
    h = g(1)*ud.filters.h_bass + g(2)*ud.filters.h_mid + g(3)*ud.filters.h_treble;
    nfft = 16384;
    H = fft(h, nfft);
    f = (0 : nfft/2) * ud.fs / nfft;
    resp = 20 * log10(abs(H(1 : nfft/2 + 1)) + 1e-6);
    f = f(2:end);  resp = resp(2:end);

    cla(ax);
    plot(ax, f, resp, 'Color', [0.2 0.8 0.9], 'LineWidth', 3);
    hold(ax, 'on');
    plot(ax, [20 20000], [0 0], 'w--', 'LineWidth', 1);
    xline(ax, ud.filters.fc_low,  '--', 'Bass|Mid',    'Color', 'cyan',   'LineWidth', 1.5);
    xline(ax, ud.filters.fc_high, '--', 'Mid|Treble',  'Color', 'yellow', 'LineWidth', 1.5);

    % Green above 0 dB, red below
    boost = max(resp, 0);
    cut   = min(resp, 0);
    if max(boost) > 0.1
        fill(ax, [f fliplr(f)], [boost zeros(size(boost))], 'g', ...
            'FaceAlpha', 0.2, 'EdgeColor', 'none');
    end
    if min(cut) < -0.1
        fill(ax, [f fliplr(f)], [cut zeros(size(cut))], 'r', ...
            'FaceAlpha', 0.2, 'EdgeColor', 'none');
    end
    ax.XLim = [20 min(20000, ud.fs / 2)];
end

%% ============================ Playback ==============================

function playAudio(fig, useEQ)
    ud = fig.UserData;
    if isempty(ud.audioData), return; end
    stopAudio(fig);
    if useEQ
        y = ud.processedAudio;
    else
        y = ud.audioData;
    end
    fig.UserData.player = audioplayer(y, ud.fs);
    play(fig.UserData.player);
end

function stopAudio(fig)
    p = fig.UserData.player;
    if ~isempty(p)
        try
            stop(p);
        catch
        end
    end
end

function saveProcessedAudio(fig)
    ud = fig.UserData;
    if isempty(ud.processedAudio), return; end
    [filename, pathname] = uiputfile('*.wav', 'Save Processed Audio', 'equalised.wav');
    figure(fig);
    if isequal(filename, 0), return; end
    try
        audiowrite(fullfile(pathname, filename), ud.processedAudio, ud.fs);
        uialert(fig, ['Saved: ' fullfile(pathname, filename)], 'Saved', 'Icon', 'success');
    catch ME
        uialert(fig, sprintf('Could not save: %s', ME.message), 'Error');
    end
end

function closeApp(fig)
    stopAudio(fig);
    delete(fig);
end
