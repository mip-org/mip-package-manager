function load(packageName, varargin)
    % load - Load a mip package into MATLAB path
    %
    % Usage:
    %   mip.load('packageName')
    %   mip.load('packageName', '--pin')
    %
    % This function loads the specified package from ~/.mip/packages by
    % executing its load_package.m file. Use '--pin' to automatically pin the package.
    
    % Check for --pin flag in arguments
    pinPackage = false;
    remainingArgs = {};
    for i = 1:length(varargin)
        if ischar(varargin{i}) && strcmp(varargin{i}, '--pin')
            pinPackage = true;
        else
            remainingArgs{end+1} = varargin{i};
        end
    end
    
    % Parse optional arguments for internal use
    p = inputParser;
    addParameter(p, 'loadingStack', {}, @iscell);
    addParameter(p, 'isDirect', true, @islogical);
    parse(p, remainingArgs{:});
    loadingStack = p.Results.loadingStack;
    isDirect = p.Results.isDirect;
    
    % Check for circular dependencies
    if ismember(packageName, loadingStack)
        cycle = strjoin([loadingStack, {packageName}], ' -> ');
        error('mip:circularDependency', ...
              'Circular dependency detected: %s', cycle);
    end

    % Add to loading stack for circular dependency detection
    loadingStack = [loadingStack, {packageName}];

    % Get the mip packages directory based on the location of this load_package.m file
    % load.m is located at ~/.mip/matlab/+mip/load.m
    % We need to go up to ~/.mip/packages/
    loadFileDir = fileparts(mfilename('fullpath'));
    mipRootDir = fileparts(fileparts(loadFileDir));
    packagesDir = fullfile(mipRootDir, 'packages');
    
    % Check if packages directory exists
    if ~exist(packagesDir, 'dir')
        error('mip:packagesDirectoryNotFound', ...
              ['The mip packages directory does not exist: %s\n' ...
               'Please run "mip setup" from the command line to set up mip.'], ...
              packagesDir);
    end
    
    packageDir = fullfile(packagesDir, packageName);
    
    % Check if package exists
    if ~exist(packageDir, 'dir')
        error('mip:packageNotFound', ...
              'Package "%s" is not installed. Run "mip install %s" first.', ...
              packageName, packageName);
    end
    
    % Check if package is already loaded
    if isPackageLoaded(packageName)
        % If this is a direct load and the package was previously
        % loaded as a dependency, mark it as direct now
        if isDirect && ~isPackageDirectlyLoaded(packageName)
            markPackageAsDirect(packageName);
            fprintf('Package "%s" is already loaded (now marked as direct)\n', packageName);
        else
            fprintf('Package "%s" is already loaded\n', packageName);
        end
        return;
    end
    
    % Check for mip.json and process dependencies
    mipJsonPath = fullfile(packageDir, 'mip.json');
    if exist(mipJsonPath, 'file')
        try
            % Read and parse mip.json
            fid = fopen(mipJsonPath, 'r');
            jsonText = fread(fid, '*char')';
            fclose(fid);
            mipConfig = jsondecode(jsonText);

            % Load dependencies first
            if isfield(mipConfig, 'dependencies') && ~isempty(mipConfig.dependencies)
                fprintf('Loading dependencies for "%s": %s\n', ...
                        packageName, strjoin(mipConfig.dependencies, ', '));
                for i = 1:length(mipConfig.dependencies)
                    dep = mipConfig.dependencies{i};
                    if ~isPackageLoaded(dep)
                        mip.load(dep, 'loadingStack', loadingStack, 'isDirect', false);
                    else
                        fprintf('  Dependency "%s" is already loaded\n', dep);
                    end
                end
            end
        catch ME
            warning('mip:jsonParseError', ...
                    'Could not parse mip.json for package "%s": %s', ...
                    packageName, ME.message);
        end
    end
    
    % Look for load_package.m file
    loadFile = fullfile(packageDir, 'load_package.m');
    if ~exist(loadFile, 'file')
        error('mip:loadNotFound', ...
              'Package "%s" does not have a load_package.m file', packageName);
    end

    % Execute the load_package.m file
    originalDir = pwd;
    cd(packageDir);
    try
        run(loadFile);
        fprintf('Loaded package "%s"\n', packageName);
    catch ME
        warning('mip:loadError', ...
                'Error executing load_package.m for package "%s": %s', ...
                packageName, ME.message);
    end
    cd(originalDir);

    % Mark package as loaded
    markPackageAsLoaded(packageName, isDirect);

    % Pin package if requested
    if pinPackage && isDirect
        mip.pin(packageName);
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

function markPackageAsLoaded(packageName, isDirect)
    % Helper function to mark a package as loaded
    global MIP_LOADED_PACKAGES;
    global MIP_DIRECTLY_LOADED_PACKAGES;

    if isempty(MIP_LOADED_PACKAGES)
        MIP_LOADED_PACKAGES = {};
    end
    if ~ismember(packageName, MIP_LOADED_PACKAGES)
        MIP_LOADED_PACKAGES{end+1} = packageName;
    end

    % Track directly loaded packages separately
    if isDirect
        markPackageAsDirect(packageName);
    end
end

function markPackageAsDirect(packageName)
    % Helper function to mark a package as directly loaded
    global MIP_DIRECTLY_LOADED_PACKAGES;

    if isempty(MIP_DIRECTLY_LOADED_PACKAGES)
        MIP_DIRECTLY_LOADED_PACKAGES = {};
    end
    if ~ismember(packageName, MIP_DIRECTLY_LOADED_PACKAGES)
        MIP_DIRECTLY_LOADED_PACKAGES{end+1} = packageName;
    end
end

function direct = isPackageDirectlyLoaded(packageName)
    % Helper function to check if a package is directly loaded
    global MIP_DIRECTLY_LOADED_PACKAGES;
    if isempty(MIP_DIRECTLY_LOADED_PACKAGES)
        MIP_DIRECTLY_LOADED_PACKAGES = {};
    end
    direct = ismember(packageName, MIP_DIRECTLY_LOADED_PACKAGES);
end
