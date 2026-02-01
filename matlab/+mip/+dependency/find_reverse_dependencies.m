function reverseDeps = find_reverse_dependencies(packageName, packagesDir, visited)
%FIND_REVERSE_DEPENDENCIES   Find all packages that depend on a given package.
%
% Args:
%   packageName - Name of the package to find reverse dependencies for
%   packagesDir - Path to the packages directory
%   visited - (Optional) Cell array of already visited packages
%
% Returns:
%   reverseDeps - Cell array of package names that depend on the given package
%
% Example:
%   deps = mip.dependency.find_reverse_dependencies('mypackage', '~/.mip/packages');

if nargin < 3
    visited = {};
end

% Avoid infinite recursion
if ismember(packageName, visited)
    reverseDeps = {};
    return
end

visited = [visited, {packageName}];
reverseDeps = {};

% Check if packages directory exists
if ~exist(packagesDir, 'dir')
    return
end

% Scan all installed packages
dirContents = dir(packagesDir);

for i = 1:length(dirContents)
    if ~dirContents(i).isdir || startsWith(dirContents(i).name, '.')
        continue
    end

    pkgName = dirContents(i).name;

    % Skip the package itself
    if strcmp(pkgName, packageName)
        continue
    end

    % Read this package's dependencies
    pkgDir = fullfile(packagesDir, pkgName);
    try
        pkgInfo = mip.utils.read_package_json(pkgDir);
        dependencies = pkgInfo.dependencies;

        if ~iscell(dependencies)
            dependencies = {dependencies};
        end

        % If this package depends on our target package
        if ismember(packageName, dependencies)
            reverseDeps = [reverseDeps, {pkgName}]; %#ok<*AGROW>
            % Recursively find packages that depend on this package
            transitiveDeps = mip.dependency.find_reverse_dependencies(pkgName, packagesDir, visited);
            reverseDeps = [reverseDeps, transitiveDeps];
        end
    catch
        % Ignore packages with missing or invalid mip.json
        continue
    end
end

% Remove duplicates
reverseDeps = unique(reverseDeps, 'stable');

end
