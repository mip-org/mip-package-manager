function install(packageNames)
    % INSTALL Install one or more mip packages
    %
    % Usage:
    %   mip.install('packageName')
    %   mip.install({'package1', 'package2', 'package3'})
    %   mip.install('/path/to/package.mhl')
    %   mip.install('https://example.com/package.mhl')
    %
    % Args:
    %   packageNames - Package name(s), .mhl file path(s), or URL(s)
    %                  Can be a string, char array, or cell array
    %
    % This function installs packages from the mip repository, local .mhl files,
    % or URLs. Dependencies are automatically resolved and installed.
    %
    % Examples:
    %   mip.install('chebfun')
    %   mip.install({'package1', 'package2'})
    %   mip.install('/home/user/mypackage.mhl')
    
    % Normalize input to cell array
    if ischar(packageNames) || isstring(packageNames)
        packageNames = {char(packageNames)};
    elseif ~iscell(packageNames)
        error('mip:invalidInput', ...
              'packageNames must be a string, char array, or cell array');
    end
    
    packagesDir = mip.utils.get_packages_dir();
    
    % Create packages directory if it doesn't exist
    if ~exist(packagesDir, 'dir')
        mkdir(packagesDir);
    end
    
    % Separate packages by type
    repoPackages = {};
    mhlSources = {};
    
    for i = 1:length(packageNames)
        pkg = packageNames{i};
        if endsWith(pkg, '.mhl') || startsWith(pkg, 'http://') || startsWith(pkg, 'https://')
            mhlSources = [mhlSources, {pkg}]; %#ok<AGROW>
        else
            repoPackages = [repoPackages, {pkg}]; %#ok<AGROW>
        end
    end
    
    % Handle repository packages
    installedCount = 0;
    
    if ~isempty(repoPackages)
        installedCount = installedCount + installFromRepository(repoPackages, packagesDir);
    end
    
    % Handle .mhl file installations
    for i = 1:length(mhlSources)
        if installFromMhl(mhlSources{i}, packagesDir)
            installedCount = installedCount + 1;
        end
    end
    
    % Summary
    if installedCount == 0 && isempty(mhlSources)
        fprintf('\nAll packages already installed.\n');
    elseif installedCount > 0
        fprintf('\nSuccessfully installed %d package(s).\n', installedCount);
    end
end

function count = installFromRepository(repoPackages, packagesDir)
    % Install packages from the mip repository
    
    count = 0;
    
    try
        % Download and parse package index
        indexUrl = 'https://mip-org.github.io/mip-core/index.json';
        fprintf('Fetching package index...\n');
        
        tempFile = [tempname, '.json'];
        websave(tempFile, indexUrl);
        indexJson = fileread(tempFile);
        delete(tempFile);
        
        index = jsondecode(indexJson);
        
        % Get current architecture
        currentArch = mip.arch();
        fprintf('Detected architecture: %s\n', currentArch);
        
        % Group packages by name
        packagesByName = containers.Map('KeyType', 'char', 'ValueType', 'any');
        % index.packages from jsondecode - handle both struct array and cell array
        packages = index.packages;
        
        % Determine how to access packages based on type
        for i = 1:length(packages)
            % Handle both cell arrays and struct arrays
            if iscell(packages)
                pkg = packages{i};  % Cell array access
            else
                pkg = packages(i);   % Struct array access
            end
            
            % Extract package name
            if isstruct(pkg)
                pkgName = pkg.name;
            else
                error('mip:invalidPackageFormat', 'Invalid package format in index');
            end
            
            if ~packagesByName.isKey(pkgName)
                packagesByName(pkgName) = {};
            end
            variants = packagesByName(pkgName);
            packagesByName(pkgName) = [variants, {pkg}];
        end
        
        % Select best variant for each package
        packageInfoMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
        unavailablePackages = containers.Map('KeyType', 'char', 'ValueType', 'any');
        
        packageNames = keys(packagesByName);
        for i = 1:length(packageNames)
            pkgName = packageNames{i};
            variants = packagesByName(pkgName);
            bestVariant = selectBestVariant(variants, currentArch);
            
            if ~isempty(bestVariant)
                packageInfoMap(pkgName) = bestVariant;
            else
                % Track packages with no compatible variant
                availableArchs = {};
                for j = 1:length(variants)
                    availableArchs = [availableArchs, {variants{j}.architecture}]; %#ok<AGROW>
                end
                unavailablePackages(pkgName) = unique(availableArchs);
            end
        end
        
        % Check if any requested packages are unavailable
        for i = 1:length(repoPackages)
            pkgName = repoPackages{i};
            if ~packageInfoMap.isKey(pkgName)
                if unavailablePackages.isKey(pkgName)
                    archs = unavailablePackages(pkgName);
                    fprintf('\nError: Package "%s" is not available for architecture "%s"\n', ...
                            pkgName, currentArch);
                    fprintf('Available architectures: %s\n', strjoin(archs, ', '));
                    error('mip:packageUnavailable', 'Package not available for this architecture');
                else
                    error('mip:packageNotFound', ...
                          'Package "%s" not found in repository', pkgName);
                end
            end
        end
        
        % Resolve dependencies
        if length(repoPackages) == 1
            fprintf('Resolving dependencies for "%s"...\n', repoPackages{1});
        else
            fprintf('Resolving dependencies for %d packages...\n', length(repoPackages));
        end
        
        % Build combined dependency graph
        allRequired = {};
        for i = 1:length(repoPackages)
            pkgName = repoPackages{i};
            installOrder = mip.dependency.build_dependency_graph(pkgName, packageInfoMap);
            allRequired = [allRequired, installOrder]; %#ok<AGROW>
        end
        allRequired = unique(allRequired, 'stable');
        
        % Sort topologically
        allPackagesToInstall = mip.dependency.topological_sort(allRequired, packageInfoMap);
        
        % Filter out already installed packages
        toInstall = {};
        alreadyInstalled = {};
        
        for i = 1:length(allPackagesToInstall)
            pkgName = allPackagesToInstall{i};
            pkgDir = fullfile(packagesDir, pkgName);
            if exist(pkgDir, 'dir')
                alreadyInstalled = [alreadyInstalled, {pkgName}]; %#ok<AGROW>
            else
                toInstall = [toInstall, {pkgName}]; %#ok<AGROW>
            end
        end
        
        % Report already installed packages
        for i = 1:length(alreadyInstalled)
            fprintf('Package "%s" is already installed\n', alreadyInstalled{i});
        end
        
        % Show installation plan
        if ~isempty(toInstall)
            if length(toInstall) == 1
                fprintf('\nInstallation plan:\n');
            else
                fprintf('\nInstallation plan (%d packages):\n', length(toInstall));
            end
            
            for i = 1:length(toInstall)
                pkgName = toInstall{i};
                pkgInfo = packageInfoMap(pkgName);
                fprintf('  - %s %s\n', pkgName, pkgInfo.version);
            end
            fprintf('\n');
            
            % Install each package
            for i = 1:length(toInstall)
                pkgName = toInstall{i};
                pkgInfo = packageInfoMap(pkgName);
                downloadAndInstall(pkgName, pkgInfo, packagesDir);
                count = count + 1;
            end
        end
        
    catch ME
        rethrow(ME);
    end
end

function success = installFromMhl(mhlSource, packagesDir)
    % Install a package from a local .mhl file or URL
    
    success = false;
    tempDir = tempname;
    mkdir(tempDir);
    
    try
        % Download or copy the .mhl file
        mhlPath = mip.utils.download_file(mhlSource, tempDir);
        
        % Extract the .mhl file
        extractDir = fullfile(tempDir, 'extracted');
        mip.utils.extract_mhl(mhlPath, extractDir);
        
        % Read mip.json to get package name and dependencies
        pkgInfo = mip.utils.read_package_json(extractDir);
        packageName = pkgInfo.name;
        
        % Check if package is already installed
        pkgDir = fullfile(packagesDir, packageName);
        if exist(pkgDir, 'dir')
            fprintf('Package "%s" is already installed\n', packageName);
            return;
        end
        
        % Install dependencies from remote repository if any
        if ~isempty(pkgInfo.dependencies)
            fprintf('\nPackage "%s" has dependencies: %s\n', ...
                    packageName, strjoin(pkgInfo.dependencies, ', '));
            fprintf('Installing dependencies from remote repository...\n');
            installFromRepository(pkgInfo.dependencies, packagesDir);
        end
        
        % Install the package
        fprintf('\nInstalling "%s"...\n', packageName);
        
        % Move extracted files to packages directory
        movefile(extractDir, pkgDir);
        
        fprintf('Successfully installed "%s"\n', packageName);
        success = true;
        
    catch ME
        % Clean up on error
        if exist(tempDir, 'dir')
            rmdir(tempDir, 's');
        end
        rethrow(ME);
    end
    
    % Clean up temp directory
    if exist(tempDir, 'dir')
        rmdir(tempDir, 's');
    end
end

function downloadAndInstall(packageName, packageInfo, packagesDir)
    % Download and install a single package
    
    mhlUrl = packageInfo.mhl_url;
    fprintf('Downloading %s %s...\n', packageName, packageInfo.version);
    
    tempDir = tempname;
    mkdir(tempDir);
    
    try
        % Download .mhl file
        mhlPath = mip.utils.download_file(mhlUrl, tempDir);
        
        % Extract to package directory
        pkgDir = fullfile(packagesDir, packageName);
        mip.utils.extract_mhl(mhlPath, pkgDir);
        
        fprintf('Successfully installed "%s"\n', packageName);
        
    catch ME
        % Clean up on error
        if exist(tempDir, 'dir')
            rmdir(tempDir, 's');
        end
        if exist(pkgDir, 'dir')
            rmdir(pkgDir, 's');
        end
        rethrow(ME);
    end
    
    % Clean up temp directory
    if exist(tempDir, 'dir')
        rmdir(tempDir, 's');
    end
end

function bestVariant = selectBestVariant(variants, currentArch)
    % Select the best package variant for the current architecture
    
    if isempty(variants)
        bestVariant = [];
        return;
    end
    
    % Filter to compatible variants (exact match or 'any')
    compatible = {};
    for i = 1:length(variants)
        v = variants{i};
        % Access architecture field safely
        if isfield(v, 'architecture')
            arch = v.architecture;
        else
            % Skip variants without architecture field
            continue;
        end
        
        if strcmp(arch, currentArch) || strcmp(arch, 'any')
            compatible = [compatible, {v}]; %#ok<AGROW>
        end
    end
    
    if isempty(compatible)
        bestVariant = [];
        return;
    end
    
    % Prefer exact architecture matches over 'any'
    exactMatches = {};
    for i = 1:length(compatible)
        v = compatible{i};
        arch = v.architecture;
        if strcmp(arch, currentArch)
            exactMatches = [exactMatches, {v}]; %#ok<AGROW>
        end
    end
    
    if ~isempty(exactMatches)
        bestVariant = exactMatches{1};
    else
        bestVariant = compatible{1};
    end
end
