function musical_notes = generate_musical_notes(template_results, varargin)
    p = inputParser;
    addParameter(p, 'Debug', false, @islogical);
    parse(p, varargin{:});

    musical_notes = struct(...
        'sign', {}, ...
        'type', {}, ...
        'length', {}, ...
        'octave', {});

    % get clef position
    clef = template_results(1);

    categories = {
        'space_0', ...
        'line_1', ...
        'space_1', ...
        'line_2', ...
        'space_2', ...
        'line_3', ...
        'space_3', ...
        'line_4', ...
        'space_4'
    };

    % clef category
    clef_category = clef.line_category;

    % get the position of the clef for offsetting to C
    clef_position = find(strcmp(categories, clef_category)) + 2;

    note_signs = { 'B', 'A', 'G', 'F', 'E', 'D', 'C' };

    % get the position of the notes
    for i = 2:length(template_results)
        % if it's a mora, we can skip it
        if strcmp(template_results(i).type, 'mora')
            continue;
        end

        note = template_results(i);
        note_category = note.line_category;
        note_position = find(strcmp(categories, note_category));

        % calculate the note position relative to C
        note_position = note_position - clef_position;

        % calculate the note sign
        note_sign = note_signs{mod(note_position, 7) + 1};

        % calculate the note length punctum - 1, clivis - 2, podatus - 2, scandicus - 3, climacus - 3, torculus - 3
        note_length = 1;
        if strcmp(note.type, 'clivis') || strcmp(note.type, 'podatus')
            note_length = 2;
        elseif strcmp(note.type, 'scandicus') || strcmp(note.type, 'climacus') || strcmp(note.type, 'torculus')
            note_length = 3;
        end

        % check if the next note is a mora
        if i < length(template_results) && strcmp(template_results(i+1).type, 'mora')
            note_length = note_length + 1;
        end


        % store the note sign and length at the next index
        musical_notes(end+1) = struct(...
            'sign', note_sign, ...
            'type', note.type, ...
            'length', note_length, ...
            'octave', abs(floor(note_position / 7)));

    end

    if p.Results.Debug
        % Display musical notes
        disp('Musical Notes:');
        for i = 1:length(musical_notes)
            fprintf('Note %d:\n', i);
            fprintf('  Sign: %s\n', musical_notes(i).sign);
            fprintf('  Type: %s\n', musical_notes(i).type);
            fprintf('  Length: %d\n', musical_notes(i).length);
            fprintf('  Octave: %d\n\n', musical_notes(i).octave);
        end
    end
end