function config = parse_yaml(yamlPath)
%PARSE_YAML   Parse a YAML file and return a MATLAB struct.
%
% Args:
%   yamlPath - Path to the YAML file
%
% Returns:
%   config - MATLAB struct representing the YAML content

if ~exist(yamlPath, 'file')
    error('mip:yamlNotFound', 'YAML file not found: %s', yamlPath);
end

config = parse_yaml_pure(yamlPath);

end

function result = parse_yaml_pure(yamlPath)
    text = fileread(yamlPath);
    lines = strsplit(text, '\n', 'CollapseDelimiters', false);

    % Remove trailing empty lines
    while ~isempty(lines) && isempty(strtrim(lines{end}))
        lines(end) = [];
    end

    [result, ~] = parse_mapping(lines, 1, 0);
end

function [result, idx] = parse_mapping(lines, startIdx, baseIndent)
    result = struct();
    idx = startIdx;

    while idx <= length(lines)
        line = lines{idx};

        % Skip empty lines and comments
        stripped = strtrim(line);
        if isempty(stripped) || stripped(1) == '#'
            idx = idx + 1;
            continue;
        end

        indent = count_indent(line);

        % If we've dedented past our level, we're done
        if indent < baseIndent
            return;
        end

        % Check if this is a list item at our level
        if startsWith(stripped, '- ')
            return;
        end

        % Must be a key: value line
        colonPos = find(stripped == ':', 1);
        if isempty(colonPos)
            idx = idx + 1;
            continue;
        end

        key = strtrim(stripped(1:colonPos-1));
        key = make_valid_field(key);
        rest = strtrim(stripped(colonPos+1:end));

        % Remove inline comment
        rest = remove_inline_comment(rest);

        if isempty(rest)
            % Value is on subsequent indented lines — could be mapping or list
            nextIdx = idx + 1;
            [nextIndent, nextStripped] = peek_next(lines, nextIdx);

            if nextIndent > indent && startsWith(nextStripped, '- ')
                [val, idx] = parse_list(lines, nextIdx, nextIndent);
            elseif nextIndent > indent
                [val, idx] = parse_mapping(lines, nextIdx, nextIndent);
            else
                val = '';
                idx = nextIdx;
            end
            result.(key) = val;
        else
            result.(key) = parse_value(rest);
            idx = idx + 1;
        end
    end
end

function [result, idx] = parse_list(lines, startIdx, baseIndent)
    result = {};
    idx = startIdx;

    while idx <= length(lines)
        line = lines{idx};
        stripped = strtrim(line);

        if isempty(stripped) || stripped(1) == '#'
            idx = idx + 1;
            continue;
        end

        indent = count_indent(line);

        if indent < baseIndent
            break;
        end

        if indent == baseIndent && startsWith(stripped, '- ')
            itemText = strtrim(stripped(3:end));
            itemText = remove_inline_comment(itemText);

            % The item's mapping keys live at indent of the content after "- "
            itemKeyIndent = baseIndent + 2;

            % Check if item is a key: value (mapping entry)
            colonPos = find(itemText == ':', 1);
            if ~isempty(colonPos) && colonPos < length(itemText)
                % Inline mapping item like "- key: value"
                key = strtrim(itemText(1:colonPos-1));
                val = strtrim(itemText(colonPos+1:end));
                val = remove_inline_comment(val);
                item = struct(make_valid_field(key), parse_value(val));

                % Check for continuation lines under this key
                nextIdx = idx + 1;
                [nextIndent, nextStripped] = peek_next(lines, nextIdx);
                if nextIndent > itemKeyIndent && ~isempty(nextStripped) && ~startsWith(nextStripped, '- ')
                    [submap, idx] = parse_mapping(lines, nextIdx, nextIndent);
                    fnames = fieldnames(submap);
                    for k = 1:length(fnames)
                        item.(fnames{k}) = submap.(fnames{k});
                    end
                else
                    idx = nextIdx;
                end

                % Collect sibling keys at itemKeyIndent
                [item, idx] = collect_sibling_keys(lines, idx, itemKeyIndent, item);

                result{end+1} = item;
            elseif ~isempty(colonPos) && colonPos == length(itemText)
                % Item is "- key:" with value on next lines
                key = strtrim(itemText(1:colonPos-1));
                nextIdx = idx + 1;
                [nextIndent, nextStripped] = peek_next(lines, nextIdx);
                if nextIndent > itemKeyIndent
                    if startsWith(nextStripped, '- ')
                        [subval, idx] = parse_list(lines, nextIdx, nextIndent);
                    else
                        [subval, idx] = parse_mapping(lines, nextIdx, nextIndent);
                    end
                else
                    subval = '';
                    idx = nextIdx;
                end
                item = struct(make_valid_field(key), {subval});

                % Collect sibling keys at itemKeyIndent
                [item, idx] = collect_sibling_keys(lines, idx, itemKeyIndent, item);

                result{end+1} = item;
            else
                % Simple scalar item
                result{end+1} = parse_value(itemText);
                idx = idx + 1;
            end
        elseif indent > baseIndent
            % Skip unexpected continuation lines
            idx = idx + 1;
        else
            break;
        end
    end

    % If all items are simple scalars (strings/numbers), convert to array
    allScalar = true;
    allString = true;
    allNumeric = true;
    for k = 1:length(result)
        if isstruct(result{k})
            allScalar = false;
            break;
        end
        if ~ischar(result{k}) && ~isstring(result{k})
            allString = false;
        end
        if ~isnumeric(result{k})
            allNumeric = false;
        end
    end

    if allScalar && allString && ~isempty(result)
        result = cellfun(@char, result, 'UniformOutput', false);
    end
end

function val = parse_value(s)
    if isempty(s)
        val = '';
        return;
    end

    % Flow-style list: [a, b, c]
    if s(1) == '[' && s(end) == ']'
        inner = strtrim(s(2:end-1));
        if isempty(inner)
            val = {};
            return;
        end
        parts = strsplit(inner, ',');
        val = cellfun(@(x) parse_scalar(strtrim(x)), parts, 'UniformOutput', false);
        % Try to make all-string lists consistent
        allStr = all(cellfun(@(x) ischar(x) || isstring(x), val));
        if allStr
            val = cellfun(@char, val, 'UniformOutput', false);
        end
        return;
    end

    val = parse_scalar(s);
end

function val = parse_scalar(s)
    % Quoted string
    if (s(1) == '"' && s(end) == '"') || (s(1) == '''' && s(end) == '''')
        val = s(2:end-1);
        return;
    end

    % Boolean
    if strcmpi(s, 'true')
        val = true;
        return;
    end
    if strcmpi(s, 'false')
        val = false;
        return;
    end

    % Null
    if strcmpi(s, 'null') || strcmp(s, '~')
        val = '';
        return;
    end

    % Number
    num = str2double(s);
    if ~isnan(num) && ~any(isspace(s))
        val = num;
        return;
    end

    % Plain string
    val = s;
end

function n = count_indent(line)
    n = 0;
    for k = 1:length(line)
        if line(k) == ' '
            n = n + 1;
        else
            break;
        end
    end
end

function [indent, stripped] = peek_next(lines, idx)
    indent = -1;
    stripped = '';
    while idx <= length(lines)
        s = strtrim(lines{idx});
        if ~isempty(s) && s(1) ~= '#'
            indent = count_indent(lines{idx});
            stripped = s;
            return;
        end
        idx = idx + 1;
    end
end

function key = make_valid_field(key)
    % Make a string safe for use as a MATLAB struct field name
    key = strrep(key, '-', '_');
    key = strrep(key, '.', '_');
    if ~isempty(key) && (key(1) >= '0' && key(1) <= '9')
        key = ['x' key];
    end
end

function [item, idx] = collect_sibling_keys(lines, idx, itemKeyIndent, item)
    % After parsing the first key of a list item, collect any sibling keys
    % that appear at the same indent level (e.g., build_only: true)
    while idx <= length(lines)
        [nextIndent, nextStripped] = peek_next(lines, idx);
        if nextIndent == itemKeyIndent && ~startsWith(nextStripped, '- ')
            colonPos = find(nextStripped == ':', 1);
            if ~isempty(colonPos)
                sibKey = strtrim(nextStripped(1:colonPos-1));
                sibRest = strtrim(nextStripped(colonPos+1:end));
                sibRest = remove_inline_comment(sibRest);

                % Advance idx to the actual line (skip blanks/comments)
                while idx <= length(lines)
                    s = strtrim(lines{idx});
                    if ~isempty(s) && s(1) ~= '#'
                        break;
                    end
                    idx = idx + 1;
                end

                if ~isempty(sibRest)
                    item.(make_valid_field(sibKey)) = parse_value(sibRest);
                    idx = idx + 1;
                else
                    nextIdx2 = idx + 1;
                    [ni2, ns2] = peek_next(lines, nextIdx2);
                    if ni2 > itemKeyIndent
                        if startsWith(ns2, '- ')
                            [subval, idx] = parse_list(lines, nextIdx2, ni2);
                        else
                            [subval, idx] = parse_mapping(lines, nextIdx2, ni2);
                        end
                    else
                        subval = '';
                        idx = nextIdx2;
                    end
                    item.(make_valid_field(sibKey)) = subval;
                end
            else
                break;
            end
        else
            break;
        end
    end
end

function s = remove_inline_comment(s)
    % Remove trailing comments (# ...) but not inside quotes
    inSingle = false;
    inDouble = false;
    for k = 1:length(s)
        if s(k) == '"' && ~inSingle
            inDouble = ~inDouble;
        elseif s(k) == '''' && ~inDouble
            inSingle = ~inSingle;
        elseif s(k) == '#' && ~inSingle && ~inDouble
            if k == 1 || s(k-1) == ' '
                s = strtrim(s(1:k-1));
                return;
            end
        end
    end
end
