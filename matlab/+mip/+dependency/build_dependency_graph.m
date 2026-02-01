function depList = build_dependency_graph(packageName, packageInfoMap, visited, path)
%BUILD_DEPENDENCY_GRAPH   Recursively build dependency graph for a package.
%
% Args:
%   packageName - Name of the package
%   packageInfoMap - Map (containers.Map or struct) of package name -> package info
%   visited - (Optional) Cell array of already visited packages
%   path - (Optional) Cell array representing current dependency path
%
% Returns:
%   depList - Cell array of package names in dependency order (dependencies first)
%
% Example:
%   deps = mip.dependency.build_dependency_graph('mypackage', pkgMap);

if nargin < 3
    visited = {};
end
if nargin < 4
    path = {};
end

% Check for circular dependency
if ismember(packageName, path)
    cycle = strjoin([path, {packageName}], ' -> ');
    error('mip:circularDependency', ...
          'Circular dependency detected: %s', cycle);
end

% If already visited, skip
if ismember(packageName, visited)
    depList = {};
    return
end

% Find package info
if isa(packageInfoMap, 'containers.Map')
    if ~isKey(packageInfoMap, packageName)
        error('mip:packageNotFound', ...
              'Package "%s" not found in repository', packageName);
    end
    pkgInfo = packageInfoMap(packageName);
elseif isstruct(packageInfoMap)
    if ~isfield(packageInfoMap, packageName)
        error('mip:packageNotFound', ...
              'Package "%s" not found in repository', packageName);
    end
    pkgInfo = packageInfoMap.(packageName);
else
    error('mip:invalidPackageMap', ...
          'packageInfoMap must be a containers.Map or struct');
end

% Mark as visited and add to path
visited = [visited, {packageName}];
path = [path, {packageName}];

% Collect all dependencies first
depList = {};
dependencies = pkgInfo.dependencies;
% Handle empty arrays (jsondecode returns 0x0 double for [])
if isempty(dependencies) || (isnumeric(dependencies) && isempty(dependencies))
    dependencies = {};
elseif ~iscell(dependencies)
    dependencies = {dependencies};
end

for i = 1:length(dependencies)
    dep = dependencies{i};
    subDeps = mip.dependency.build_dependency_graph(dep, packageInfoMap, visited, path);
    depList = [depList, subDeps]; %#ok<*AGROW>
end

% Then add this package
depList = [depList, {packageName}];

end
