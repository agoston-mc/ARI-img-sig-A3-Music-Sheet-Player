function category = categorize_vertical_position(y_pos, staff_lines)
    % Ensure staff lines are sorted
    staff_lines = sort(staff_lines);

    % Define categories based on staff lines
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

    % Check position relative to staff lines with 8-pixel proximity
    proximity_threshold = 8;

    if y_pos < staff_lines(1) - proximity_threshold
        category = categories{1};  % highest space
    elseif y_pos >= staff_lines(1) - proximity_threshold && y_pos < staff_lines(1)
        category = categories{2};  % first line
    elseif  y_pos > staff_lines(1) && y_pos < staff_lines(2) - proximity_threshold
        category = categories{3};  % space below first line
    elseif y_pos >= staff_lines(2) - proximity_threshold && y_pos < staff_lines(2)
        category = categories{4};  % second line
    elseif y_pos > staff_lines(2) && y_pos < staff_lines(3) - proximity_threshold
        category = categories{5};  % space below second line
    elseif y_pos >= staff_lines(3) - proximity_threshold && y_pos < staff_lines(3)
        category = categories{6};  % third line
    elseif y_pos > staff_lines(3) && y_pos < staff_lines(4) - proximity_threshold
        category = categories{7};  % space below third line
    elseif y_pos >= staff_lines(4) - proximity_threshold && y_pos < staff_lines(4)
        category = categories{8};  % fourth line
    else
        category = categories{9};  % space below fourth line
    end
end