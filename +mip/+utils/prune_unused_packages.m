function prune_unused_packages()
%PRUNE_UNUSED_PACKAGES   Remove installed packages that are no longer needed.
%
% A package is considered needed if it is in `directly_installed.txt` or
% is a transitive dependency of any directly-installed package.
%
% `mip-org/core/mip` (the package manager itself) is never pruned.
%
% Used by:
%   - `mip uninstall`: prune orphans after removing requested packages.
%   - `mip install`: roll back successfully-installed dependencies when a
%     later package in the same operation fails.

    allInstalled = mip.utils.list_installed_packages();

    if isempty(allInstalled)
        return
    end

    directlyInstalled = mip.utils.get_directly_installed();

    % Build set of all needed packages (directly installed + their dependencies)
    neededPackages = {};
    for i = 1:length(directlyInstalled)
        directPkg = directlyInstalled{i};
        if ismember(directPkg, allInstalled)
            neededPackages = [neededPackages, getAllDependencies(directPkg)]; %#ok<AGROW>
        end
    end

    neededPackages = unique([directlyInstalled, neededPackages]);

    % Find packages to prune (installed but not needed)
    % Never prune mip-org/core/mip - it is the package manager itself
    packagesToPrune = {};
    for i = 1:length(allInstalled)
        fqn = allInstalled{i};
        if ~ismember(fqn, neededPackages) && ...
                ~strcmp(fqn, 'mip-org/core/mip')
            packagesToPrune{end+1} = fqn; %#ok<AGROW>
        end
    end

    if ~isempty(packagesToPrune)
        fprintf('\nPruning unnecessary packages: %s\n', strjoin(packagesToPrune, ', '));
        for i = 1:length(packagesToPrune)
            fqn = packagesToPrune{i};
            r = mip.utils.parse_package_arg(fqn);
            pkgDir = mip.utils.get_package_dir(r.org, r.channel, r.name);

            try
                rmdir(pkgDir, 's');
                fprintf('  Pruned package "%s"\n', fqn);
                cleanupEmptyDirs(fullfile(mip.utils.get_packages_dir(), r.org, r.channel));
                cleanupEmptyDirs(fullfile(mip.utils.get_packages_dir(), r.org));
            catch ME
                warning('mip:pruneFailed', ...
                        'Failed to prune package "%s": %s', fqn, ME.message);
            end
        end
    end
end

function deps = getAllDependencies(fqn)
    deps = {};

    result = mip.utils.parse_package_arg(fqn);
    if ~result.is_fqn
        return
    end

    pkgDir = mip.utils.get_package_dir(result.org, result.channel, result.name);
    mipJsonPath = fullfile(pkgDir, 'mip.json');

    if ~exist(mipJsonPath, 'file')
        return
    end

    try
        fid = fopen(mipJsonPath, 'r');
        jsonText = fread(fid, '*char')';
        fclose(fid);
        mipConfig = jsondecode(jsonText);

        if isfield(mipConfig, 'dependencies') && ~isempty(mipConfig.dependencies)
            depNames = mipConfig.dependencies;
            if ~iscell(depNames)
                depNames = {depNames};
            end
            for i = 1:length(depNames)
                dep = depNames{i};
                depResult = mip.utils.parse_package_arg(dep);
                if depResult.is_fqn
                    depFqn = dep;
                else
                    % Same channel first, then resolve
                    sameDir = mip.utils.get_package_dir(result.org, result.channel, dep);
                    if exist(sameDir, 'dir')
                        depFqn = mip.utils.make_fqn(result.org, result.channel, dep);
                    else
                        depFqn = mip.utils.resolve_bare_name(dep);
                        if isempty(depFqn)
                            continue
                        end
                    end
                end
                if ~ismember(depFqn, deps)
                    deps{end+1} = depFqn; %#ok<AGROW>
                    transitiveDeps = getAllDependencies(depFqn);
                    deps = unique([deps, transitiveDeps]);
                end
            end
        end
    catch ME
        warning('mip:jsonParseError', ...
                'Could not parse mip.json for package "%s": %s', ...
                fqn, ME.message);
    end
end

function cleanupEmptyDirs(dirPath)
% Remove directory if it is empty (no subdirectories or files)
    if ~exist(dirPath, 'dir')
        return
    end
    contents = dir(dirPath);
    % Filter out . and ..
    contents = contents(~ismember({contents.name}, {'.', '..'}));
    if isempty(contents)
        rmdir(dirPath);
    end
end
