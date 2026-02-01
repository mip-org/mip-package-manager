function uninstall(varargin)
%UNINSTALL   Uninstall one or more mip packages.
%
% Usage:
%   mip.uninstall('packageName')
%   mip.uninstall('package1', 'package2', 'package3')
%
% Args:
%   Package name(s) to uninstall, as strings or char arrays.
%
% This function uninstalls packages and all packages that depend on them.
% User confirmation is required before proceeding.

    if nargin < 1
        error('mip:uninstall:noPackage', ...
              'At least one package name is required for uninstall command.');
    end

    packageNames = varargin;
    packagesDir = mip.utils.get_packages_dir();

    % Check which requested packages are installed
    notInstalled = {};
    requestedPackages = {};

    for i = 1:length(packageNames)
        pkgName = packageNames{i};
        pkgDir = fullfile(packagesDir, pkgName);
        if ~exist(pkgDir, 'dir')
            notInstalled = [notInstalled, {pkgName}]; %#ok<*AGROW>
        else
            requestedPackages = [requestedPackages, {pkgName}];
        end
    end

    % Report packages that aren't installed
    for i = 1:length(notInstalled)
        fprintf('Package "%s" is not installed\n', notInstalled{i});
    end

    % If no valid packages to uninstall, return
    if isempty(requestedPackages)
        return
    end

    % Find all packages that depend on any of the requested packages
    if length(requestedPackages) == 1
        fprintf('Scanning for packages that depend on "%s"...\n', requestedPackages{1});
    else
        fprintf('Scanning for packages that depend on %d packages...\n', length(requestedPackages));
    end

    allToUninstall = requestedPackages;
    for i = 1:length(requestedPackages)
        pkgName = requestedPackages{i};
        reverseDeps = mip.dependency.find_reverse_dependencies(pkgName, packagesDir);
        allToUninstall = [allToUninstall, reverseDeps];
    end
    allToUninstall = unique(allToUninstall, 'stable');

    % Sort packages in proper uninstallation order (reverse dependencies first)
    toUninstall = buildUninstallOrder(allToUninstall, packagesDir);

    % Display uninstallation plan
    if length(toUninstall) > 1
        fprintf('\nThe following packages will be uninstalled:\n');
        for i = 1:length(toUninstall)
            pkg = toUninstall{i};
            if ismember(pkg, requestedPackages)
                fprintf('  - %s\n', pkg);
            else
                % Find which requested packages this depends on
                fprintf('  - %s (depends on a package being uninstalled)\n', pkg);
            end
        end
        fprintf('\n');
    end

    % Confirm uninstallation
    % Note: input() may not work in all MATLAB contexts (e.g., deployed applications)
    % This is a limitation of MATLAB's interactive input capabilities
    if length(toUninstall) == 1
        response = input(sprintf('Are you sure you want to uninstall "%s"? (y/n): ', toUninstall{1}), 's');
    else
        response = input(sprintf('Are you sure you want to uninstall these %d packages? (y/n): ', length(toUninstall)), 's');
    end

    if ~strcmpi(response, 'y') && ~strcmpi(response, 'yes')
        fprintf('Uninstallation cancelled\n');
        return
    end

    % Execute uninstallations
    fprintf('\n');
    uninstalledCount = 0;
    for i = 1:length(toUninstall)
        pkg = toUninstall{i};
        pkgDir = fullfile(packagesDir, pkg);
        if exist(pkgDir, 'dir')
            try
                fprintf('Uninstalling "%s"...\n', pkg);
                rmdir(pkgDir, 's');
                fprintf('Successfully uninstalled "%s"\n', pkg);
                uninstalledCount = uninstalledCount + 1;
            catch ME
                error('mip:uninstallFailed', ...
                      'Failed to uninstall package "%s": %s', pkg, ME.message);
            end
        end
    end
    fprintf('\nSuccessfully uninstalled %d package(s)\n', uninstalledCount);
end

function uninstallOrder = buildUninstallOrder(packagesToUninstall, packagesDir)
% Sort packages in reverse topological order for uninstallation
% Packages with reverse dependencies should be uninstalled first

    % Build dependency graph for packages to uninstall
    dependencies = containers.Map('KeyType', 'char', 'ValueType', 'any');

    for i = 1:length(packagesToUninstall)
        pkgName = packagesToUninstall{i};
        pkgDir = fullfile(packagesDir, pkgName);
        try
            pkgInfo = mip.utils.read_package_json(pkgDir);
            deps = pkgInfo.dependencies;
            % read_package_json now always returns a cell array
        catch
            deps = {};
        end
        dependencies(pkgName) = deps;
    end

    % Topological sort - but we want reverse order for uninstallation
    visited = containers.Map('KeyType', 'char', 'ValueType', 'logical');
    uninstallOrder = {};

    function visit(pkgName)
        if visited.isKey(pkgName)
            return
        end
        visited(pkgName) = true;

        % Visit packages that depend on this one first (from our uninstall set)
        for j = 1:length(packagesToUninstall)
            otherPkg = packagesToUninstall{j};
            if ~strcmp(otherPkg, pkgName) && dependencies.isKey(otherPkg)
                otherDeps = dependencies(otherPkg);
                if ismember(pkgName, otherDeps)
                    visit(otherPkg);
                end
            end
        end

        uninstallOrder = [uninstallOrder, {pkgName}];
    end

    for i = 1:length(packagesToUninstall)
        visit(packagesToUninstall{i});
    end
end
