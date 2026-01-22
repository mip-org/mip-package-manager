function sortedPackages = topological_sort(packageNames, packageInfoMap)
    % TOPOLOGICAL_SORT Sort packages in topological order (dependencies first)
    %
    % Args:
    %   packageNames - Cell array of package names to sort
    %   packageInfoMap - Map (containers.Map or struct) of package name -> package info
    %
    % Returns:
    %   sortedPackages - Cell array of package names in topological order
    %
    % Example:
    %   sorted = mip.dependency.topological_sort({'pkg1', 'pkg2'}, pkgMap);
    
    if isempty(packageNames)
        sortedPackages = {};
        return;
    end
    
    % Build adjacency list (package -> list of dependencies)
    dependencies = containers.Map('KeyType', 'char', 'ValueType', 'any');
    
    for i = 1:length(packageNames)
        pkgName = packageNames{i};
        
        % Get package info
        if isa(packageInfoMap, 'containers.Map')
            if isKey(packageInfoMap, pkgName)
                pkgInfo = packageInfoMap(pkgName);
            else
                pkgInfo = struct('dependencies', {{}});
            end
        elseif isstruct(packageInfoMap) && isfield(packageInfoMap, pkgName)
            pkgInfo = packageInfoMap.(pkgName);
        else
            pkgInfo = struct('dependencies', {{}});
        end
        
        % Get dependencies
        if isfield(pkgInfo, 'dependencies')
            deps = pkgInfo.dependencies;
            % Handle empty arrays (jsondecode returns 0x0 double for [])
            if isempty(deps) || (isnumeric(deps) && isempty(deps))
                deps = {};
            elseif ~iscell(deps)
                deps = {deps};
            end
        else
            deps = {};
        end
        
        dependencies(pkgName) = deps;
    end
    
    % Topological sort using DFS
    visited = containers.Map('KeyType', 'char', 'ValueType', 'logical');
    sortedPackages = {};
    
    function visit(pkgName)
        if visited.isKey(pkgName)
            return;
        end
        visited(pkgName) = true;
        
        % Visit dependencies first
        if dependencies.isKey(pkgName)
            deps = dependencies(pkgName);
            for j = 1:length(deps)
                dep = deps{j};
                if ismember(dep, packageNames)
                    visit(dep);
                end
            end
        end
        
        sortedPackages = [sortedPackages, {pkgName}]; %#ok<AGROW>
    end
    
    % Visit all packages
    for i = 1:length(packageNames)
        visit(packageNames{i});
    end
end
