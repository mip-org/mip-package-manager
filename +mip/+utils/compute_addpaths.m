function paths = compute_addpaths(baseDir, addpathsConfig)
%COMPUTE_ADDPATHS   Compute resolved path list from mip.yaml addpaths config.
%
% Args:
%   baseDir        - The base directory of the package
%   addpathsConfig - Cell array of addpath entries from mip.yaml
%                    Each entry is either a struct with .path (and optional
%                    .recursive, .exclude) or a string.
%
% Returns:
%   paths - Cell array of resolved relative path strings

paths = {};

for i = 1:length(addpathsConfig)
    item = addpathsConfig{i};
    if ischar(item)
        paths{end+1} = item; %#ok<AGROW>
    elseif isstruct(item)
        p = item.path;
        if isfield(item, 'recursive') && item.recursive
            exclude = {};
            if isfield(item, 'exclude')
                exclude = item.exclude;
                if ~iscell(exclude)
                    exclude = {exclude};
                end
            end
            fullPath = fullfile(baseDir, p);
            recPaths = findRecursivePaths(fullPath, exclude);
            paths = [paths, recPaths]; %#ok<AGROW>
        else
            paths{end+1} = p; %#ok<AGROW>
        end
    end
end

end


function paths = findRecursivePaths(baseDir, excludeDirs)
% Recursively find directories containing .m files.
    paths = {};
    if ~exist(baseDir, 'dir')
        return;
    end

    items = dir(baseDir);
    hasMFiles = false;
    for i = 1:length(items)
        if ~items(i).isdir && endsWith(items(i).name, '.m')
            hasMFiles = true;
            break;
        end
    end

    if hasMFiles
        paths{end+1} = baseDir;
    end

    for i = 1:length(items)
        if items(i).isdir && ~startsWith(items(i).name, '.') && ...
                ~ismember(items(i).name, excludeDirs)
            subPaths = findRecursivePaths(fullfile(baseDir, items(i).name), excludeDirs);
            paths = [paths, subPaths]; %#ok<AGROW>
        end
    end
end
