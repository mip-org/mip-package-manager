function uninstall(varargin)
%UNINSTALL   Uninstall one or more mip packages.
%
% Usage:
%   mip.uninstall('packageName')
%   mip.uninstall('org/channel/packageName')
%   mip.uninstall('package1', 'package2')
%
% Accepts both bare package names and fully qualified names.
% This function uninstalls packages and then prunes any packages that
% are no longer needed (packages that were installed as dependencies
% but are not dependencies of any directly installed package).

    if nargin < 1
        error('mip:uninstall:noPackage', ...
              'At least one package name is required for uninstall command.');
    end

    packageArgs = varargin;

    % Resolve all package arguments to FQNs
    notInstalled = {};
    resolvedPackages = {};

    for i = 1:length(packageArgs)
        arg = packageArgs{i};
        result = mip.utils.parse_package_arg(arg);

        if result.is_fqn
            fqn = arg;
            pkgDir = mip.utils.get_package_dir(result.org, result.channel, result.name);
        else
            allMatches = mip.utils.find_all_installed_by_name(result.name);
            if isempty(allMatches)
                notInstalled = [notInstalled, {arg}]; %#ok<*AGROW>
                continue
            elseif length(allMatches) > 1
                fprintf('Package name "%s" is ambiguous. It is installed in multiple channels:\n', result.name);
                for k = 1:length(allMatches)
                    fprintf('  %s\n', allMatches{k});
                end
                fprintf('Please specify the fully qualified name to uninstall.\n');
                continue
            end
            fqn = allMatches{1};
            r = mip.utils.parse_package_arg(fqn);
            pkgDir = mip.utils.get_package_dir(r.org, r.channel, r.name);
        end

        if ~exist(pkgDir, 'dir')
            notInstalled = [notInstalled, {arg}];
        else
            resolvedPackages = [resolvedPackages, {fqn}];
        end
    end

    % mip-org/core/mip cannot be uninstalled via this command
    if ismember('mip-org/core/mip', resolvedPackages)
        fprintf('Cannot uninstall mip via "mip uninstall".\n');
        fprintf('To uninstall mip manually:\n');
        fprintf('  1. Remove the mip directory: %s\n', mip.root());
        fprintf('  2. Remove the mip entry from your MATLAB path (e.g., using pathtool)\n');
        resolvedPackages = resolvedPackages(~strcmp(resolvedPackages, 'mip-org/core/mip'));
    end

    % Report packages that aren't installed
    for i = 1:length(notInstalled)
        fprintf('Package "%s" is not installed\n', notInstalled{i});
    end

    if isempty(resolvedPackages)
        return
    end

    % Unload any packages that are currently loaded
    for i = 1:length(resolvedPackages)
        fqn = resolvedPackages{i};
        if mip.utils.is_loaded(fqn)
            mip.unload(fqn);
        end
    end

    % Uninstall each requested package
    fprintf('\n');
    for i = 1:length(resolvedPackages)
        fqn = resolvedPackages{i};
        r = mip.utils.parse_package_arg(fqn);
        pkgDir = mip.utils.get_package_dir(r.org, r.channel, r.name);

        try
            fprintf('Uninstalling "%s"...\n', fqn);
            rmdir(pkgDir, 's');
            fprintf('Uninstalled package "%s"\n', fqn);
        catch ME
            error('mip:uninstallFailed', ...
                  'Failed to uninstall package "%s": %s', fqn, ME.message);
        end

        % Remove from directly installed packages
        mip.utils.remove_directly_installed(fqn);

        % Clean up empty parent directories
        cleanupEmptyDirs(fullfile(mip.utils.get_packages_dir(), r.org, r.channel));
        cleanupEmptyDirs(fullfile(mip.utils.get_packages_dir(), r.org));
    end

    % Prune packages that are no longer needed
    mip.utils.prune_unused_packages();

    % After pruning, check for broken dependencies
    checkForBrokenDependencies();
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

function checkForBrokenDependencies()
    allInstalled = mip.utils.list_installed_packages();

    if isempty(allInstalled)
        return
    end

    brokenDeps = {};
    for i = 1:length(allInstalled)
        fqn = allInstalled{i};
        r = mip.utils.parse_package_arg(fqn);
        pkgDir = mip.utils.get_package_dir(r.org, r.channel, r.name);
        mipJsonPath = fullfile(pkgDir, 'mip.json');

        if ~exist(mipJsonPath, 'file')
            continue
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
                for j = 1:length(depNames)
                    dep = depNames{j};
                    depResult = mip.utils.parse_package_arg(dep);
                    if depResult.is_fqn
                        depR = mip.utils.parse_package_arg(dep);
                        depDir = mip.utils.get_package_dir(depR.org, depR.channel, depR.name);
                        if ~exist(depDir, 'dir')
                            brokenDeps{end+1} = sprintf('Package "%s" depends on "%s" which is not installed', fqn, dep); %#ok<AGROW>
                        end
                    else
                        resolved = mip.utils.resolve_bare_name(dep);
                        if isempty(resolved)
                            brokenDeps{end+1} = sprintf('Package "%s" depends on "%s" which is not installed', fqn, dep); %#ok<AGROW>
                        end
                    end
                end
            end
        catch
        end
    end

    if ~isempty(brokenDeps)
        warning('mip:brokenDependencies', ...
                'Warning: Some installed packages have missing dependencies:\n  %s', ...
                strjoin(brokenDeps, '\n  '));
    end
end
