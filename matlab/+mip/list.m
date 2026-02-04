function list()
%LIST   List all installed mip packages.
%
% Usage:
%   mip.list()
%
% Displays all currently installed packages with their versions.
% Loaded packages are shown in a separate section at the top.
% An asterisk (*) indicates a directly loaded package.
% [pinned] indicates a pinned package.
%
% Example:
%   mip.list()
%   % Output:
%   % === Loaded Packages ===
%   %  * chebfun (5.7.0) [pinned]
%   %    dependency1 (1.0.0)
%   %
%   % === Other Installed Packages ===
%   %    package1 (1.2.3)

packagesDir = mip.utils.get_packages_dir();

if ~exist(packagesDir, 'dir')
    fprintf('No packages installed yet\n');
    return
end

% Get list of package directories
dirContents = dir(packagesDir);
packages = {};

for i = 1:length(dirContents)
    if dirContents(i).isdir && ~startsWith(dirContents(i).name, '.')
        packages = [packages, {dirContents(i).name}]; %#ok<AGROW>
    end
end

if isempty(packages)
    fprintf('No packages installed yet\n');
    return
end

% Get loaded and pinned packages
MIP_LOADED_PACKAGES          = mip.utils.key_value_get('MIP_LOADED_PACKAGES');
MIP_DIRECTLY_LOADED_PACKAGES = mip.utils.key_value_get('MIP_DIRECTLY_LOADED_PACKAGES');
MIP_PINNED_PACKAGES          = mip.utils.key_value_get('MIP_PINNED_PACKAGES');

% Categorize packages into loaded and not loaded
loadedPackages = {};
notLoadedPackages = {};

for i = 1:length(packages)
    pkgName = packages{i};
    if ismember(pkgName, MIP_LOADED_PACKAGES)
        loadedPackages{end+1} = pkgName; %#ok<AGROW>
    else
        notLoadedPackages{end+1} = pkgName; %#ok<AGROW>
    end
end

% Sort both lists alphabetically
loadedPackages = sort(loadedPackages);
notLoadedPackages = sort(notLoadedPackages);

% Display loaded packages section
if ~isempty(loadedPackages)
    fprintf('=== Loaded Packages ===\n');
    for i = 1:length(loadedPackages)
        pkgName = loadedPackages{i};
        pkgDir = fullfile(packagesDir, pkgName);

        % Try to read version from mip.json
        version = 'unknown';
        try
            pkgInfo = mip.utils.read_package_json(pkgDir);
            if isfield(pkgInfo, 'version')
                version = pkgInfo.version;
            end
        catch
            % Ignore errors reading mip.json
        end

        % Check if direct and pinned
        isDirect = ismember(pkgName, MIP_DIRECTLY_LOADED_PACKAGES);
        isPinned = ismember(pkgName, MIP_PINNED_PACKAGES);
        
        % Build the display line with proper indentation
        if isDirect
            prefix = ' *';
        else
            prefix = '  ';
        end
        
        pkgLine = sprintf('%s %s (%s)', prefix, pkgName, version);
        
        % Add pinned indicator
        if isPinned
            pkgLine = sprintf('%s [pinned]', pkgLine);
        end
        
        fprintf('%s\n', pkgLine);
    end
    fprintf('\n');
end

% Display not loaded packages section
if ~isempty(notLoadedPackages)
    fprintf('=== Other Installed Packages ===\n');
    for i = 1:length(notLoadedPackages)
        pkgName = notLoadedPackages{i};
        pkgDir = fullfile(packagesDir, pkgName);

        % Try to read version from mip.json
        version = 'unknown';
        try
            pkgInfo = mip.utils.read_package_json(pkgDir);
            if isfield(pkgInfo, 'version')
                version = pkgInfo.version;
            end
        catch
            % Ignore errors reading mip.json
        end

        fprintf('   %s (%s)\n', pkgName, version);
    end
end

end
