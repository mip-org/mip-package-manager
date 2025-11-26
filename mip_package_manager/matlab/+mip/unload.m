function unload(packageName)
    % unload - Unload a mip package from MATLAB path
    %
    % Usage:
    %   mip.unload('packageName')
    %   mip.unload('--all')
    %
    % This function unloads the specified package by executing its
    % unload_package.m file (if it exists) and then prunes any packages that
    % are no longer needed (packages that were loaded as dependencies
    % but are not dependencies of any directly loaded package).
    %
    % Use '--all' to unload all non-pinned packages.

    global MIP_LOADED_PACKAGES;
    global MIP_DIRECTLY_LOADED_PACKAGES;
    global MIP_PINNED_PACKAGES;
    
    % Handle --all flag
    if strcmp(packageName, '--all')
        unloadAll();
        return;
    end

    % Check if package is loaded
    if ~isPackageLoaded(packageName)
        fprintf('Package "%s" is not currently loaded\n', packageName);
        return;
    end
    
    % Warn if package is pinned
    if isPackagePinned(packageName)
        warning('mip:pinnedPackage', ...
                'Package "%s" is pinned. It will be unloaded anyway.', packageName);
    end
    
    % Get the mip packages directory
    loadFileDir = fileparts(mfilename('fullpath'));
    mipRootDir = fileparts(fileparts(loadFileDir));
    packagesDir = fullfile(mipRootDir, 'packages');
    packageDir = fullfile(packagesDir, packageName);
    
    % Execute unload_package.m if it exists
    executeUnload(packageDir, packageName);
    
    % Remove from pinned packages if it was pinned
    if ~isempty(MIP_PINNED_PACKAGES)
        MIP_PINNED_PACKAGES = MIP_PINNED_PACKAGES(...
            ~strcmp(MIP_PINNED_PACKAGES, packageName));
    end
    
    % Remove from directly loaded packages
    if ~isempty(MIP_DIRECTLY_LOADED_PACKAGES)
        MIP_DIRECTLY_LOADED_PACKAGES = MIP_DIRECTLY_LOADED_PACKAGES(...
            ~strcmp(MIP_DIRECTLY_LOADED_PACKAGES, packageName));
    end

    % Remove from loaded packages
    if ~isempty(MIP_LOADED_PACKAGES)
        MIP_LOADED_PACKAGES = MIP_LOADED_PACKAGES(...
            ~strcmp(MIP_LOADED_PACKAGES, packageName));
    end

    fprintf('Unloaded package "%s"\n', packageName);
    
    % Prune packages that are no longer needed
    pruneUnusedPackages(packagesDir);
end

function executeUnload(packageDir, packageName)
    % Execute unload_package.m for a package if it exists
    unloadFile = fullfile(packageDir, 'unload_package.m');
    
    if ~exist(unloadFile, 'file')
        warning('mip:unloadNotFound', ...
                'Package "%s" does not have a unload_package.m file. Path changes may persist.', ...
                packageName);
        return;
    end

    % Execute the unload_package.m file
    originalDir = pwd;
    cd(packageDir);
    try
        run(unloadFile);
    catch ME
        warning('mip:unloadError', ...
                'Error executing unload_package.m for package "%s": %s', ...
                packageName, ME.message);
    end
    cd(originalDir);
end

function pruneUnusedPackages(packagesDir)
    % Prune packages that are no longer needed
    % A package is needed if it is:
    % 1. Directly loaded by the user, OR
    % 2. A dependency of a directly loaded package

    global MIP_LOADED_PACKAGES;
    global MIP_DIRECTLY_LOADED_PACKAGES;

    if isempty(MIP_LOADED_PACKAGES)
        return;
    end

    if isempty(MIP_DIRECTLY_LOADED_PACKAGES)
        MIP_DIRECTLY_LOADED_PACKAGES = {};
    end

    % Build set of all needed packages (directly loaded + their dependencies)
    neededPackages = {};
    for i = 1:length(MIP_DIRECTLY_LOADED_PACKAGES)
        directPkg = MIP_DIRECTLY_LOADED_PACKAGES{i};
        neededPackages = [neededPackages, getAllDependencies(directPkg, packagesDir)];
    end

    % Add directly loaded packages themselves
    neededPackages = unique([MIP_DIRECTLY_LOADED_PACKAGES, neededPackages]);

    % Find packages to prune (loaded but not needed)
    packagesToPrune = {};
    for i = 1:length(MIP_LOADED_PACKAGES)
        pkg = MIP_LOADED_PACKAGES{i};
        if ~ismember(pkg, neededPackages)
            packagesToPrune{end+1} = pkg;
        end
    end
    
    % Prune each unnecessary package
    if ~isempty(packagesToPrune)
        fprintf('Pruning unnecessary packages: %s\n', strjoin(packagesToPrune, ', '));
        for i = 1:length(packagesToPrune)
            pkg = packagesToPrune{i};
            packageDir = fullfile(packagesDir, pkg);
            
            % Execute unload_package.m
            executeUnload(packageDir, pkg);
            
            % Remove from loaded packages
            MIP_LOADED_PACKAGES = MIP_LOADED_PACKAGES(...
                ~strcmp(MIP_LOADED_PACKAGES, pkg));
            
            fprintf('  Pruned package "%s"\n', pkg);
        end
    end
end

function deps = getAllDependencies(packageName, packagesDir)
    % Recursively get all dependencies of a package
    deps = {};
    
    packageDir = fullfile(packagesDir, packageName);
    mipJsonPath = fullfile(packageDir, 'mip.json');
    
    if ~exist(mipJsonPath, 'file')
        return;
    end
    
    try
        % Read and parse mip.json
        fid = fopen(mipJsonPath, 'r');
        jsonText = fread(fid, '*char')';
        fclose(fid);
        mipConfig = jsondecode(jsonText);
        
        % Get direct dependencies
        if isfield(mipConfig, 'dependencies') && ~isempty(mipConfig.dependencies)
            for i = 1:length(mipConfig.dependencies)
                dep = mipConfig.dependencies{i};
                if ~ismember(dep, deps)
                    deps{end+1} = dep;
                    % Recursively get dependencies of this dependency
                    transitiveDeps = getAllDependencies(dep, packagesDir);
                    deps = unique([deps, transitiveDeps]);
                end
            end
        end
    catch ME
        warning('mip:jsonParseError', ...
                'Could not parse mip.json for package "%s": %s', ...
                packageName, ME.message);
    end
end

function unloadAll()
    % Unload all non-pinned packages
    global MIP_LOADED_PACKAGES;
    global MIP_PINNED_PACKAGES;

    if isempty(MIP_LOADED_PACKAGES)
        fprintf('No packages are currently loaded\n');
        return;
    end
    
    if isempty(MIP_PINNED_PACKAGES)
        MIP_PINNED_PACKAGES = {};
    end
    
    % Get the mip packages directory
    loadFileDir = fileparts(mfilename('fullpath'));
    mipRootDir = fileparts(fileparts(loadFileDir));
    packagesDir = fullfile(mipRootDir, 'packages');
    
    % Find packages to unload (all except pinned)
    packagesToUnload = {};
    for i = 1:length(MIP_LOADED_PACKAGES)
        pkg = MIP_LOADED_PACKAGES{i};
        if ~ismember(pkg, MIP_PINNED_PACKAGES)
            packagesToUnload{end+1} = pkg;
        end
    end

    if isempty(packagesToUnload)
        fprintf('No non-pinned packages to unload\n');
        if ~isempty(MIP_PINNED_PACKAGES)
            fprintf('Pinned packages remain: %s\n', strjoin(MIP_PINNED_PACKAGES, ', '));
        end
        return;
    end

    fprintf('Unloading all non-pinned packages: %s\n', strjoin(packagesToUnload, ', '));

    % Unload each package
    for i = 1:length(packagesToUnload)
        pkg = packagesToUnload{i};
        packageDir = fullfile(packagesDir, pkg);

        % Execute unload_package.m
        executeUnload(packageDir, pkg);
        fprintf('  Unloaded package "%s"\n', pkg);
    end
    
    % Update global variables - remove all non-pinned packages
    global MIP_DIRECTLY_LOADED_PACKAGES;

    % Keep only pinned packages in loaded list
    MIP_LOADED_PACKAGES = MIP_PINNED_PACKAGES;

    % Keep only pinned packages in directly loaded list
    if ~isempty(MIP_DIRECTLY_LOADED_PACKAGES)
        MIP_DIRECTLY_LOADED_PACKAGES = MIP_DIRECTLY_LOADED_PACKAGES(...
            ismember(MIP_DIRECTLY_LOADED_PACKAGES, MIP_PINNED_PACKAGES));
    end
    
    if ~isempty(MIP_PINNED_PACKAGES)
        fprintf('\nPinned packages remain loaded: %s\n', strjoin(MIP_PINNED_PACKAGES, ', '));
    end
end

function loaded = isPackageLoaded(packageName)
    % Helper function to check if a package has already been loaded
    global MIP_LOADED_PACKAGES;
    if isempty(MIP_LOADED_PACKAGES)
        MIP_LOADED_PACKAGES = {};
    end
    loaded = ismember(packageName, MIP_LOADED_PACKAGES);
end

function pinned = isPackagePinned(packageName)
    % Helper function to check if a package is pinned
    global MIP_PINNED_PACKAGES;
    if isempty(MIP_PINNED_PACKAGES)
        MIP_PINNED_PACKAGES = {};
    end
    pinned = ismember(packageName, MIP_PINNED_PACKAGES);
end
