function [freq_list, s, fs] = play_musical_notes(musical_notes, varargin)
    % Play musical notes based on their sign, type, and length

    p = inputParser;
    addParameter(p, 'Debug', false, @islogical);
    addParameter(p, 'SampleRate', 44100, @isnumeric);
    addParameter(p, 'BaseDuration', 1, @isnumeric);
    addParameter(p, 'savefreq', false, @islogical);
    addParameter(p, 'play', true, @islogical);
    addParameter(p, 'EchoDelay', 0.2, @isnumeric);  % Echo delay in seconds
    addParameter(p, 'EchoDecay', 0.5, @isnumeric);  % Echo decay factor
    addParameter(p, 'Peakless', false, @islogical);  % Remove peaks from the audio signal
    parse(p, varargin{:});

    freq_list = struct(...
        'freq', {}, ...
        'duration', {}, ...
        'tone', {});

    % Sample parameters
    sample_rate = p.Results.SampleRate;  % Standard audio sample rate
    base_duration = p.Results.BaseDuration;  % Base note duration in seconds
    echo_delay = p.Results.EchoDelay;
    echo_decay = p.Results.EchoDecay;

    % Frequency mapping for notes (in Hz)
    % Adjusted to match the note signs from the generate_musical_notes function
    note_frequencies = containers.Map({
        'C', 'D', 'E', 'F', 'G', 'A', 'B'
    }, {
        261, 293, 329, 349, 392, 440, 493 ... % integer frequencies because MATLAB
    });

    % Initialize audio signal
    audio_signal = [];

    % Organ-like timbre generation
    function organ_tone = create_organ_tone(freq, t)
        % Fundamental frequency
        fundamental = sin(2 * pi * freq * t);

        % Add harmonics typical of organ sounds
        harmonic1 = 0.5 * sin(2 * pi * (2 * freq) * t);    % 2nd harmonic
        harmonic2 = 0.25 * sin(2 * pi * (3 * freq) * t);   % 3rd harmonic
        harmonic3 = 0.125 * sin(2 * pi * (4 * freq) * t);  % 4th harmonic

        % Combine harmonics
        organ_tone = fundamental + harmonic1 + harmonic2 + harmonic3;
    end

    % Organ-like timbre generation
    function organ_transition = create_organ_transition(freq)
        % Fundamental frequency
        omega = 2 * pi * freq;
        fundamental = sin(cumsum(omega / sample_rate));

        % Add harmonics typical of organ sounds
        omega1 = 2 * pi * (2 * freq);
        harmonic1 = 0.5 * sin(cumsum(omega1 / sample_rate));    % 2nd harmonic
        omega2 = 2 * pi * (3 * freq);
        harmonic2 = 0.25 * sin(cumsum(omega2 / sample_rate));   % 3rd harmonic
        omega3 = 2 * pi * (4 * freq);
        harmonic3 = 0.125 * sin(cumsum(omega3 / sample_rate));  % 4th harmonic

        % Combine harmonics
        organ_transition = fundamental + harmonic1 + harmonic2 + harmonic3;
    end

    % Process each note
    for i = 1:length(musical_notes)
        % Skip empty notes
        if isempty(musical_notes(i).sign)
            continue;
        end

        % Get note frequency
        try
            base_freq = note_frequencies(musical_notes(i).sign) * 2^(musical_notes(i).octave);
        catch
            warning('Unknown note: %s. Skipping.', musical_notes(i).sign);
            continue;
        end

        % reset base_duration
        base_duration = p.Results.BaseDuration;

        transition_duration = 0.2; % Morph duration

        % Duration and tone generation
        switch musical_notes(i).type
            case 'punctum'
                duration = base_duration * musical_notes(i).length;
                t = linspace(0, duration, round(sample_rate * duration));
                tone = create_organ_tone(base_freq, t);

            case 'clivis'
                duration = base_duration
                if musical_notes(i).length > 2
                    duration = base_duration * 2;
                end
                base_duration = base_duration - transition_duration / 2;
                duration = duration - transition_duration / 2;

                lower_freq = base_freq / (2^(1/12));

                % Create tones with organ-like timbre
                t = linspace(0, base_duration, round(sample_rate * base_duration));
                tone1 = create_organ_tone(base_freq, t);

                % transition note
                t_transition = linspace(0, transition_duration, round(sample_rate * transition_duration));
                freq_transition = linspace(base_freq, lower_freq, length(t_transition));
                transition = create_organ_transition(freq_transition);

                % Create tones with organ-like timbre
                t = linspace(0, duration, round(sample_rate * duration));
                tone2 = create_organ_tone(lower_freq, t);

                % lazy crossfade if peakless
                if p.Results.Peakless
                    overlap = round(0.1 * sample_rate);
                    fade_in = linspace(0, 1, overlap);
                    fade_out = linspace(1, 0, overlap);
                    tone1(end-overlap+1:end) = tone1(end-overlap+1:end) .* fade_out;
                    transition(1:overlap) = transition(1:overlap) .* fade_in;
                    transition(end-overlap+1:end) = transition(end-overlap+1:end) .* fade_out;
                    tone2(1:overlap) = tone2(1:overlap) .* fade_in;
                end

                tone = ([tone1, transition, tone2]);

            case 'podatus'
                duration = base_duration;
                if musical_notes(i).length > 2
                    duration = base_duration * 2;
                end
                base_duration = base_duration - transition_duration / 2;
                duration = duration - transition_duration / 2;
                lower_freq = base_freq / (2^(1/6));

                % Create tones with organ-like timbre
                t = linspace(0, base_duration, round(sample_rate * base_duration));
                tone1 = create_organ_tone(lower_freq, t);

                % transition note
                t_transition = linspace(0, transition_duration, round(sample_rate * transition_duration));
                freq_transition = linspace(lower_freq, base_freq, length(t_transition));
                transition = create_organ_transition(freq_transition);

                % Create tones with organ-like timbre
                t = linspace(0, duration, round(sample_rate * duration));
                tone2 = create_organ_tone(base_freq, t);

                % lazy crossfade if peakless
                if p.Results.Peakless
                    overlap = round(0.1 * sample_rate);
                    fade_in = linspace(0, 1, overlap);
                    fade_out = linspace(1, 0, overlap);
                    tone1(end-overlap+1:end) = tone1(end-overlap+1:end) .* fade_out;
                    transition(1:overlap) = transition(1:overlap) .* fade_in;
                    transition(end-overlap+1:end) = transition(end-overlap+1:end) .* fade_out;
                    tone2(1:overlap) = tone2(1:overlap) .* fade_in;
                end

                tone = ([tone1, transition, tone2]);
            case 'scandicus'
                duration = base_duration;
                if musical_notes(i).length > 3
                    duration = base_duration * 2;
                end
                base_duration = base_duration - transition_duration / 2;
                duration = duration - transition_duration / 2;
                lower_freq = base_freq / (2^(1/12));
                lower_freq2 = lower_freq / (2^(1/12));

                t = linspace(0, base_duration, round(sample_rate * base_duration));
                tone1 = create_organ_tone(lower_freq2, t);

                % transition note
                t_transition = linspace(0, transition_duration, round(sample_rate * transition_duration));
                freq_transition = linspace(lower_freq2, lower_freq, length(t_transition));
                transition1 = create_organ_transition(freq_transition);

                t = linspace(0, base_duration, round(sample_rate * base_duration));
                tone2 = create_organ_tone(lower_freq, t);

                % transition note
                t_transition = linspace(0, transition_duration, round(sample_rate * transition_duration));
                freq_transition = linspace(lower_freq, base_freq, length(t_transition));
                transition2 = create_organ_transition(freq_transition);

                t = linspace(0, duration, round(sample_rate * duration));
                tone3 = create_organ_tone(base_freq, t);

                % lazy crossfade if peakless
                if p.Results.Peakless
                    overlap = round(0.1 * sample_rate);
                    fade_in = linspace(0, 1, overlap);
                    fade_out = linspace(1, 0, overlap);
                    tone1(end-overlap+1:end) = tone1(end-overlap+1:end) .* fade_out;
                    transition1(1:overlap) = transition(1:overlap) .* fade_in;
                    transition1(end-overlap+1:end) = transition(end-overlap+1:end) .* fade_out;
                    tone2(1:overlap) = tone2(1:overlap) .* fade_in;
                    transition2(1:overlap) = transition(1:overlap) .* fade_in;
                    transition2(end-overlap+1:end) = transition(end-overlap+1:end) .* fade_out;
                    tone3(1:overlap) = tone3(1:overlap) .* fade_in;
                end

                tone = ([tone1, transition1, tone2, transition2, tone3]);
            case 'climacus'
                duration = base_duration;
                if musical_notes(i).length > 3
                    duration = base_duration * 2;
                end
                base_duration = base_duration - transition_duration / 2;
                duration = duration - transition_duration / 2;
                lower_freq = base_freq / (2^(1/12));
                lower_freq2 = lower_freq / (2^(1/12));

                t = linspace(0, base_duration, round(sample_rate * base_duration));
                tone1 = create_organ_tone(base_freq, t);

                % transition note
                t_transition = linspace(0, transition_duration, round(sample_rate * transition_duration));
                freq_transition = linspace(base_freq, lower_freq, length(t_transition));
                transition1 = create_organ_transition(freq_transition);

                t = linspace(0, base_duration, round(sample_rate * base_duration));
                tone2 = create_organ_tone(lower_freq, t);

                % transition note
                t_transition = linspace(0, transition_duration, round(sample_rate * transition_duration));
                freq_transition = linspace(lower_freq, lower_freq2, length(t_transition));
                transition2 = create_organ_transition(freq_transition);

                t = linspace(0, duration, round(sample_rate * duration));
                tone3 = create_organ_tone(lower_freq2, t);

                % lazy crossfade if peakless
                if p.Results.Peakless
                    overlap = round(0.1 * sample_rate);
                    fade_in = linspace(0, 1, overlap);
                    fade_out = linspace(1, 0, overlap);
                    tone1(end-overlap+1:end) = tone1(end-overlap+1:end) .* fade_out;
                    transition1(1:overlap) = transition(1:overlap) .* fade_in;
                    transition1(end-overlap+1:end) = transition(end-overlap+1:end) .* fade_out;
                    tone2(1:overlap) = tone2(1:overlap) .* fade_in;
                    transition2(1:overlap) = transition(1:overlap) .* fade_in;
                    transition2(end-overlap+1:end) = transition(end-overlap+1:end) .* fade_out;
                    tone3(1:overlap) = tone3(1:overlap) .* fade_in;
                end
                tone = ([tone1, transition1, tone2, transition2, tone3]);

            case 'torculus'
                duration = base_duration;
                if musical_notes(i).length > 3
                    duration = base_duration * 2;
                end
                base_duration = base_duration - transition_duration / 2;
                duration = duration - transition_duration / 2;
                lower_freq = base_freq / (2^(1/12));

                t = linspace(0, base_duration, round(sample_rate * base_duration));
                tone1 = create_organ_tone(lower_freq, t);

                % transition note
                t_transition = linspace(0, transition_duration, round(sample_rate * transition_duration));
                freq_transition = linspace(lower_freq, base_freq, length(t_transition));
                transition1 = create_organ_transition(freq_transition);

                t = linspace(0, base_duration, round(sample_rate * base_duration));
                tone2 = create_organ_tone(base_freq, t);

                % transition note
                t_transition = linspace(0, transition_duration, round(sample_rate * transition_duration));
                freq_transition = linspace(base_freq, lower_freq, length(t_transition));
                transition2 = create_organ_transition(freq_transition);

                t = linspace(0, duration, round(sample_rate * duration));
                tone3 = create_organ_tone(lower_freq, t);

                % lazy crossfade if peakless
                if p.Results.Peakless
                    overlap = round(0.1 * sample_rate);
                    fade_in = linspace(0, 1, overlap);
                    fade_out = linspace(1, 0, overlap);
                    tone1(end-overlap+1:end) = tone1(end-overlap+1:end) .* fade_out;
                    transition1(1:overlap) = transition(1:overlap) .* fade_in;
                    transition1(end-overlap+1:end) = transition(end-overlap+1:end) .* fade_out;
                    tone2(1:overlap) = tone2(1:overlap) .* fade_in;
                    transition2(1:overlap) = transition(1:overlap) .* fade_in;
                    transition2(end-overlap+1:end) = transition(end-overlap+1:end) .* fade_out;
                    tone3(1:overlap) = tone3(1:overlap) .* fade_in;
                end
                
                tone = ([tone1, transition1, tone2, transition2, tone3]);
            otherwise
                duration = base_duration * musical_notes(i).length;
                tone = create_organ_tone(base_freq, duration);
        end

        % Organ-like sustained envelope
        envelope = ones(size(tone));

        % Soft attack (organ-like sustained sound)
        attack_length = round(0.2 * length(tone));
        %envelope(1:attack_length) = linspace(0, 1, attack_length).^2;
        envelope(1:attack_length) = (1 - cos(pi * (0:attack_length-1) / attack_length)) / 2;

        % Soft release
        release_length = round(0.2 * length(tone));
        %envelope(end-release_length+1:end) = linspace(1, 0, release_length).^2;
        envelope(end-release_length+1:end) = flip(envelope(1:release_length));

        tone = tone .* envelope;

        % Store frequency information
        freq_list(end+1) = struct(...
            'freq', base_freq, ...
            'duration', duration, ...
            'tone', tone);


        % Append to audio signal
        audio_signal = [audio_signal, tone];
    end

    % Add echo effect
    echo_samples = round(echo_delay * sample_rate);
    echo_signal = [zeros(1, echo_samples), audio_signal(1:end-echo_samples)];
    audio_signal = audio_signal + echo_decay * echo_signal;

    % Normalize audio
    audio_signal = audio_signal / max(abs(audio_signal));

    % Write to WAV file
    audiowrite('organ_musical_notes_output.wav', audio_signal, sample_rate);

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

    s = audio_signal;
    fs = sample_rate;

end
