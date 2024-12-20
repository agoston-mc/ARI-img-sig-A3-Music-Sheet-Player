clear
clc
close all

debug = true;
template_dir = 'templates';

image_path = 'dies_1.png';
%image_path = 'sheet_1.png';

[results, staff_lines] = find_multiple_templates(image_path, template_dir, 'Debug', debug);

musical_notes = generate_musical_notes(results, 'Debug', debug);

play_musical_notes(musical_notes, 'play', true, 'Debug', debug, 'BaseDuration', 0.5);
%[fz, s, fs] = play_musical_notes_organ(musical_notes, 'play', true, 'Debug', debug, 'BaseDuration', 0.5, 'Peakless', true);

