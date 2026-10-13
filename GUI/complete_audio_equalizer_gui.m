%% Complete Audio Equalizer GUI
function complete_audio_equalizer_gui()  % Fixed function name
    % Load filter bank
    try
        load('../Day2_MultiBand/multiband_filters.mat');
    catch
        uialert([], 'Cannot load filters. Run Day 2 scripts first!', 'Error');
        return;
    end
    
    % Create main GUI
    fig = createCompleteGUI();
    
    % Initialize data
    fig.UserData.audioData = [];
    fig.UserData.processedAudio = [];
    fig.UserData.fs = 44100;
    fig.UserData.h_bass = h_bass;
    fig.UserData.h_mid = h_mid;
    fig.UserData.h_treble = h_treble;
    fig.UserData.bassGain = 0;
    fig.UserData.midGain = 0;
    fig.UserData.trebleGain = 0;
    
    fprintf('=== Audio Equalizer GUI Ready! ===\n');
end
