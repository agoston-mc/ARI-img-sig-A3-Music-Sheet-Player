function freq_list = play_musical_notes(musical_notes, varargin)
    % Play musical notes based on their sign, type, and length

    p = inputParser;
    addParameter(p, 'Debug', false, @islogical);
    addParameter(p, 'SampleRate', 44100, @isnumeric);
    addParameter(p, 'BaseDuration', 1, @isnumeric);
    addParameter(p, 'savefreq', false, @islogical);
    addParameter(p, 'play', true, @islogical);
    parse(p, varargin{:});

    freq_list = struct(...
        'freq', {}, ...
        'duration', {}, ...
        'tone', {});

    % Sample parameters
    sample_rate = p.Results.SampleRate;  % Standard audio sample rate
    base_duration = p.Results.BaseDuration;  % Base note duration in seconds

    % Frequency mapping for notes (in Hz)
    % Adjusted to match the note signs from the generate_musical_notes function
    note_frequencies = containers.Map({
        'C', 'D', 'E', 'F', 'G', 'A', 'B'
    }, {
        261, 293, 329, 349, 392, 440, 493 ... % integer frequencies because MATLAB
    });

    % Initialize audio signal
    audio_signal = [];

    % Process each note
    for i = 1:length(musical_notes)
        % Skip empty notes
        if isempty(musical_notes(i).sign)
            continue;
        end

        % Get note frequency
        try
            freq = note_frequencies(musical_notes(i).sign) * 2^(musical_notes(i).octave);
        catch
            warning('Unknown note: %s. Skipping.', musical_notes(i).sign);
            continue;
        end

        transition_duration = 0.2; % Morph duration

        % Determine tone type
        switch musical_notes(i).type
            case 'punctum'
                % Simple sine wave
                duration = base_duration * musical_notes(i).length;
                t = linspace(0, duration, round(duration * sample_rate));
                tone = sin(2 * pi * freq * t);
            case 'clivis'
                % 3 tones, one in place, one lower, and one morph from the lower to the main tone
                t1 = linspace(0, base_duration, round(base_duration * sample_rate)); % First tone
                t_transition = linspace(0, transition_duration, round(transition_duration * sample_rate)); % Transition
                % if there was a mora, length is > 2 and we need to adjust the duration
                duration = base_duration;
                if musical_notes(i).length > 2
                    duration = base_duration * 2;
                end
                t2 = linspace(0, duration, round(duration * sample_rate)); % Second tone

                lower_freq = freq / (2^(1/12)); % One semitone lower

                % First tone
                omega1 = 2 * pi * freq; % Angular frequency of first tone
                tone1 = sin(omega1 * t1);

                freq_transition = linspace(freq, lower_freq, length(t_transition));
                omega_transition = 2 * pi * freq_transition; % Angular frequency array for transition
                % Integrate angular frequency to compute continuous phase
                phase_transition = cumsum(omega_transition / sample_rate); % Phase continuity
                tone_transition = sin(phase_transition);

                phase2_start = phase_transition(end);
                omega2 = 2 * pi * lower_freq; % Angular frequency of second tone
                tone2 = sin(omega2 * t2 + phase2_start);

                % Combine the tones
                tone = [tone1, tone_transition, tone2];

            case 'podatus'
                % two tones, one in lower, one in place, and one morph from the higher to the main tone
                % main tone, with base_duration
                t1 = linspace(0, base_duration, round(base_duration * sample_rate)); % First tone
                t_transition = linspace(0, transition_duration, round(transition_duration * sample_rate)); % Transition
                % if there was a mora, length is > 2 and we need to adjust the duration
                duration = base_duration;
                if musical_notes(i).length > 2
                    duration = base_duration * 2;
                end
                t2 = linspace(0, duration, round(duration * sample_rate)); % Second tone

                lower_freq = freq / (2^(1/6)); % One tone lower

                % First tone
                omega1 = 2 * pi * lower_freq; % Angular frequency of first tone
                tone1 = sin(omega1 * t1);

                freq_transition = linspace(lower_freq, freq, length(t_transition));
                omega_transition = 2 * pi * freq_transition; % Angular frequency array for transition
                % Integrate angular frequency to compute continuous phase
                phase_transition = cumsum(omega_transition / sample_rate); % Phase continuity
                tone_transition = sin(phase_transition);

                phase2_start = phase_transition(end);
                omega2 = 2 * pi * freq; % Angular frequency of second tone
                tone2 = sin(omega2 * t2 + phase2_start);

                % Combine the tones
                tone = [tone1, tone_transition, tone2];
            case 'scandicus'
                % 5 tones, 3 main, 2 inbetween
                t1 = linspace(0, base_duration, round(base_duration * sample_rate)); % First tone
                t2 = linspace(0, base_duration, round(base_duration * sample_rate)); % Second tone
                % if there was a mora, length is > 3 and we need to adjust the duration
                duration = base_duration;
                if musical_notes(i).length > 3
                    duration = base_duration * 2;
                end
                t3 = linspace(0, duration, round(duration * sample_rate)); % Second tone

                t_trans1 = linspace(0, transition_duration, round(transition_duration * sample_rate)); % Transition 1
                t_trans2 = linspace(0, transition_duration, round(transition_duration * sample_rate)); % Transition 2

                lower_freq = freq / (2^(1/6)); % One tone lower
                lowest_freq = freq / (2^(2/6)); % Two tones lower

                % First tone
                omega1 = 2 * pi * lowest_freq; % Angular frequency of first tone
                tone1 = sin(omega1 * t1);

                % transition1
                freq_transition1 = linspace(lowest_freq, lower_freq, length(t_trans1));
                omega_transition1 = 2 * pi * freq_transition1; % Angular frequency array for transition
                phase_transition1 = cumsum(omega_transition1 / sample_rate); % Phase continuity
                tone_transition1 = sin(phase_transition1);

                % Second tone
                omega2 = 2 * pi * lower_freq; % Angular frequency of second tone
                tone2 = sin(omega2 * t2 + phase_transition1(end));

                % transition2
                freq_transition2 = linspace(lower_freq, freq, length(t_trans2));
                omega_transition2 = 2 * pi * freq_transition2; % Angular frequency array for transition
                phase_transition2 = cumsum(omega_transition2 / sample_rate); % Phase continuity
                tone_transition2 = sin(phase_transition2);

                % Third tone
                omega3 = 2 * pi * freq; % Angular frequency of third tone
                tone3 = sin(omega3 * t3 + phase_transition2(end));

                % Combine the tones
                tone = [tone1, tone_transition1, tone2, tone_transition2, tone3];
            case 'climacus'
                % 5 tones, 3 main, 2 inbetween
                t1 = linspace(0, base_duration, round(base_duration * sample_rate)); % First tone
                t2 = linspace(0, base_duration, round(base_duration * sample_rate)); % Second tone
                % if there was a mora, length is > 3 and we need to adjust the duration
                duration = base_duration;
                if musical_notes(i).length > 3
                    duration = base_duration * 2;
                end
                t3 = linspace(0, duration, round(duration * sample_rate)); % Second tone

                t_trans1 = linspace(0, transition_duration, round(transition_duration * sample_rate)); % Transition 1
                t_trans2 = linspace(0, transition_duration, round(transition_duration * sample_rate)); % Transition 2

                lower_freq = freq / (2^(1/6)); % One tone higher
                lowest_freq = freq / (2^(2/6)); % Two tones higher

                % First tone
                omega1 = 2 * pi * freq; % Angular frequency of first tone
                tone1 = sin(omega1 * t1);

                % transition1
                freq_transition1 = linspace(freq, lower_freq, length(t_trans1));
                omega_transition1 = 2 * pi * freq_transition1; % Angular frequency array for transition
                phase_transition1 = cumsum(omega_transition1 / sample_rate); % Phase continuity
                tone_transition1 = sin(phase_transition1);

                % Second tone
                omega2 = 2 * pi * lower_freq; % Angular frequency of second tone
                tone2 = sin(omega2 * t2 + phase_transition1(end));

                % transition2
                freq_transition2 = linspace(lower_freq, lowest_freq, length(t_trans2));
                omega_transition2 = 2 * pi * freq_transition2; % Angular frequency array for transition
                phase_transition2 = cumsum(omega_transition2 / sample_rate); % Phase continuity
                tone_transition2 = sin(phase_transition2);

                % Third tone
                omega3 = 2 * pi * lowest_freq; % Angular frequency of third tone
                tone3 = sin(omega3 * t3 + phase_transition2(end));

                % Combine the tones
                tone = [tone1, tone_transition1, tone2, tone_transition2, tone3];
            case 'torculus'
                % 5 tones, 3 main, 2 inbetween
                t1 = linspace(0, base_duration, round(base_duration * sample_rate)); % First tone
                t2 = linspace(0, base_duration, round(base_duration * sample_rate)); % Second tone
                % if there was a mora, length is > 3 and we need to adjust the duration
                duration = base_duration;
                if musical_notes(i).length > 3
                    duration = base_duration * 2;
                end
                t3 = linspace(0, duration, round(duration * sample_rate)); % Second tone
                t_trans1 = linspace(0, transition_duration, round(transition_duration * sample_rate)); % Transition 1
                t_trans2 = linspace(0, transition_duration, round(transition_duration * sample_rate)); % Transition 2

                lower_freq = freq / (2^(1/6)); % One tone lower

                % First tone
                omega1 = 2 * pi * lower_freq; % Angular frequency of first tone
                tone1 = sin(omega1 * t1);

                % transition1
                freq_transition1 = linspace(lower_freq, freq, length(t_trans1));
                omega_transition1 = 2 * pi * freq_transition1; % Angular frequency array for transition
                phase_transition1 = cumsum(omega_transition1 / sample_rate); % Phase continuity
                tone_transition1 = sin(phase_transition1);

                % Second tone
                omega2 = 2 * pi * freq; % Angular frequency of second tone
                tone2 = sin(omega2 * t2 + phase_transition1(end));

                % transition2
                freq_transition2 = linspace(freq, lower_freq, length(t_trans2));
                omega_transition2 = 2 * pi * freq_transition2; % Angular frequency array for transition
                phase_transition2 = cumsum(omega_transition2 / sample_rate); % Phase continuity
                tone_transition2 = sin(phase_transition2);

                % Third tone
                omega3 = 2 * pi * lower_freq; % Angular frequency of third tone
                tone3 = sin(omega3 * t3 + phase_transition2(end));

                % Combine the tones
                tone = [tone1, tone_transition1, tone2, tone_transition2, tone3];

        end

        envelope = ones(size(tone));  % Matches tone size exactly

        % Create attack phase (first 5% of tone)
        attack_length = round(0.05 * length(tone));
        envelope(1:attack_length) = linspace(0, 1, attack_length);

        % Create release phase (last 25% of tone)
        release_length = round(0.25 * length(tone));
        envelope(end-release_length+1:end) = linspace(1, 0, release_length);

        tone = smoothdata(tone) .* envelope;


        freq_list(end+1) = struct(...
            'freq', freq, ...
            'duration', duration, ...
            'tone', tone);


        % Append to audio signal
        audio_signal = [audio_signal, tone];
    end

    % Normalize audio
    audio_signal = audio_signal / max(abs(audio_signal));

    audiowrite('musical_notes_output.wav', audio_signal, sample_rate);

    if p.Results.play
        % Play the audio
        sound(audio_signal, sample_rate);
    end

    if p.Results.savefreq
        % save freq_list to a file
        save('freq_list.mat', 'freq_list');
    end

    if p.Results.Debug
        % Display playback information
        fprintf('Playing %d notes. Total duration: %.2f seconds\n', ...
            length(musical_notes), length(audio_signal)/sample_rate);
    end
end
