function [template_results, staff_lines] = find_multiple_templates(image_path, template_dir, varargin)
    % Parse optional input arguments
    p = inputParser;
    addParameter(p, 'Threshold', 0.7, @isnumeric);
    addParameter(p, 'MinSeparation', 50, @isnumeric);
    addParameter(p, 'Debug', false, @islogical);
    parse(p, varargin{:});
    
    % Extract parameters
    threshold = p.Results.Threshold;
    min_separation = p.Results.MinSeparation;
    
    % Read the main image
    main_image = imread(image_path);

    % read templates from folder
    % add all items in the templates folder
    template_paths = dir(strcat(template_dir,'/*.png'));

    % read images to sort them by image size
    template_images = cell(1, length(template_paths));
    for i = 1:length(template_paths)
        template_images{i} = imread(fullfile('templates', template_paths(i).name));
    end

    % sort the templates by image size
    [~, idx] = sort(cellfun(@numel, template_images), 'descend');
    template_paths = template_paths(idx);

    % get the names of the templates
    template_paths = arrayfun(@(x) fullfile('templates', x.name), template_paths, 'UniformOutput', false);

    % Convert main image to grayscale if needed
    if size(main_image, 3) > 1
        main_gray = rgb2gray(main_image);
    else
        main_gray = main_image;
    end
    
    % Detect horizontal lines (staff lines)
    staff_lines = detect_staff_lines(main_gray);
    
    % Initialize results structure with additional category field
    template_results = struct(...
        'type', {}, ...
        'vertical_position', {}, ...
        'bounding_box', {}, ...
        'correlation_value', {}, ...
        'line_category', {});

    if p.Results.Debug
        % Debug figure for visualization
        figure('Position', [100, 100, 1200, 800]);
        imshow(main_image);
        hold on;

        % Color map for bounding boxes and lines
        colors = {
            [1 0 0], ... Red
            [0 1 0], ... Green
            [0 0 1], ... Blue
            [1 1 0], ... Yellow
            [0 1 1], ... Cyan
            [1 0 1]  ... Magenta
        };
    end
    
    % Mask to track used regions of the image
    used_regions_mask = false(size(main_gray));
    

    % Iterate through each template
    for i = 1:length(template_paths)
        % Read template
        template = imread(template_paths{i});
        
        % Convert template to grayscale if needed
        if size(template, 3) > 1
            template_gray = rgb2gray(template);
        else
            template_gray = template;
        end
        
        % Perform template matching
        correlation = normxcorr2(template_gray, main_gray);
        
        % Find multiple correlation peaks
        [height, width] = size(main_gray);
        [template_height, template_width] = size(template_gray);
        
        % Identify multiple correlation peaks
        peak_locations = [];
        while true
            % Find maximum correlation value
            [max_corr, max_idx] = max(correlation(:));
            
            % If correlation is below threshold, stop searching
            if max_corr < threshold
                break;
            end
            
            % Convert linear index to 2D coordinates
            [y, x] = ind2sub(size(correlation), max_idx);
            
            % Adjust coordinates to image space
            adj_y = y - template_height + 1;
            adj_x = x - template_width + 1;
            
            % Create bounding box
            % bbox = [adj_x, adj_y, template_width, template_height];
            
            % Check for overlap with used regions
            bbox_mask = false(size(main_gray));
            bbox_mask(max(1, adj_y):min(height, adj_y+template_height-1), ...
                      max(1, adj_x):min(width, adj_x+template_width-1)) = true;
            
            % Check if this match overlaps with existing regions
            if ~any(used_regions_mask(bbox_mask))
                % Update used regions mask
                used_regions_mask(bbox_mask) = true;
                
                % Store match details
                peak_locations(end+1, :) = [adj_y, adj_x, max_corr];
            end
            
            % Zero out the neighborhood of the current peak to find next matches
            y_range = max(1, y-template_height):min(size(correlation, 1), y+template_height);
            x_range = max(1, x-template_width):min(size(correlation, 2), x+template_width);
            correlation(y_range, x_range) = 0;
        end
        
        % Add found matches to results
        for j = 1:size(peak_locations, 1)
            % Determine line category
            line_category = categorize_vertical_position(peak_locations(j, 1), staff_lines);
            
            % Create bounding box
            bbox = [peak_locations(j, 2), peak_locations(j, 1), template_width, template_height];

            % get typename from template path
            [~, name, ~] = fileparts(template_paths{i});

            % cut of the number at the end of the name if it exists
            if ~isempty(regexp(name, '\d', 'once'))
                name = name(1:end-1);
            end

            % Create result struct
            current_result = struct(...
                'type', name, ...
                'vertical_position', peak_locations(j, 1), ...
                'bounding_box', {bbox}, ...
                'correlation_value', peak_locations(j, 3), ...
                'line_category', line_category);
            
            % Add to results
            if isempty(template_results)
                template_results = current_result;
            else
                template_results(end+1) = current_result;
            end

            if p.Results.Debug
                % Draw bounding box
                color = colors{mod(i-1, length(colors))+1};
                rectangle('Position', bbox, 'EdgeColor', color, 'LineWidth', 2, 'LineStyle', '--');
                text(bbox(1), bbox(2)-10, sprintf('%.2f', peak_locations(j, 3)), 'Color', color, 'FontSize', 10);
            end
        end
    end

    % Sort results by horizontal position (from left to right)
    if ~isempty(template_results)
        % Extract x-coordinates (first element of bounding box)
        x_coords = cellfun(@(x) x(1), {template_results.bounding_box});
        
        % Sort by x-coordinates
        [~, idx] = sort(x_coords);
        template_results = template_results(idx);
    end

    if p.Results.Debug

        % Draw detected staff lines
        for k = 1:length(staff_lines)
            line(xlim, [staff_lines(k), staff_lines(k)], 'Color', 'red', 'LineStyle', '--', 'LineWidth', 1);
        end

        % Save debug image
        title('Template Matching Results (With Staff Lines)');
        saveas(gcf, 'template_matching_debug.png');

        % Display results
        disp('Found Templates:');
        for i = 1:length(template_results)
            fprintf('Template %d:\n', i);
            fprintf('  Type: %s\n', template_results(i).type);
            fprintf('  Vertical Position: %d\n', template_results(i).vertical_position);
            fprintf('  Bounding Box: [%d, %d, %d, %d]\n', ...
                template_results(i).bounding_box(1), ...
                template_results(i).bounding_box(2), ...
                template_results(i).bounding_box(3), ...
                template_results(i).bounding_box(4));
            fprintf('  Correlation Value: %.4f\n', template_results(i).correlation_value);
            fprintf('  Line Category: %s\n\n', template_results(i).line_category);
        end
    end
end