function staff_lines = detect_staff_lines(image_gray)
    % Preprocess the image
    % Increase contrast
    image_adjusted = imadjust(image_gray);

    % Apply threshold to create binary image
    threshold = graythresh(image_adjusted);
    binary_image = imbinarize(image_adjusted, threshold);

    % Invert binary image (assuming staff lines are dark)
    binary_image = ~binary_image;

    % Use morphological operations to enhance horizontal lines
    se_horizontal = strel('line', 50, 0);  % Horizontal structuring element
    horizontal_lines = imopen(binary_image, se_horizontal);

    % Compute vertical projection of the binary image
    vertical_projection = sum(horizontal_lines, 2);

    % Find peaks in the vertical projection
    [~, locs] = findpeaks(vertical_projection, ...
        'MinPeakHeight', max(vertical_projection) * 0.5, ...  % Adjust height threshold
        'MinPeakDistance', 10);  % Minimum distance between peaks

    % If not enough peaks found, try adjusting parameters
    if length(locs) < 4
        [~, locs] = findpeaks(vertical_projection, ...
            'MinPeakHeight', max(vertical_projection) * 0.3, ...  % Lower height threshold
            'MinPeakDistance', 5);  % Smaller minimum distance
    end

    % Sort and select top 4 peaks
    if length(locs) >= 4
        % Sort peaks and select top 4
        [sorted_locs, ~] = sort(locs);
        staff_lines = sorted_locs(max(1, end-3):end);
    else
        % Fallback method if peaks not found reliably
        staff_line_spacing = round(mean(diff(locs)));
        base_line = locs(1);
        staff_lines = base_line + staff_line_spacing * (0:3);
    end

    % Ensure exactly 4 lines are returned and sorted
    if length(staff_lines) > 4
        staff_lines = staff_lines(end-3:end);
    elseif length(staff_lines) < 4
        error('Could not detect 4 staff lines');
    end

    % Sort the lines
    staff_lines = sort(staff_lines);
end