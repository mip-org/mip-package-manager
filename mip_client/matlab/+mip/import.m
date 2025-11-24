function import(packageName, varargin)
    % import - Import a mip package into MATLAB path
    %
    % Usage:
    %   mip.import('packageName')
    %   mip.import('packageName', '--pin')
    %
    % This function imports the specified package from ~/.mip/packages by
    % executing its setup.m file. Use '--pin' to automatically pin the package.
    
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
    addParameter(p, 'importingStack', {}, @iscell);
    addParameter(p, 'isDirect', true, @islogical);
    parse(p, remainingArgs{:});
    importingStack = p.Results.importingStack;
    isDirect = p.Results.isDirect;
    
    % Check for circular dependencies
    if ismember(packageName, importingStack)
        cycle = strjoin([importingStack, {packageName}], ' -> ');
        error('mip:circularDependency', ...
              'Circular dependency detected: %s', cycle);
    end
    
    % Add to importing stack for circular dependency detection
    importingStack = [importingStack, {packageName}];
    
    % Get the mip packages directory based on the location of this import.m file
    % import.m is located at ~/.mip/matlab/+mip/import.m
    % We need to go up to ~/.mip/packages/
    importFileDir = fileparts(mfilename('fullpath'));
    mipRootDir = fileparts(fileparts(importFileDir));
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
    
    % Check if package is already imported
    if isPackageImported(packageName)
        % If this is a direct import and the package was previously
        % imported as a dependency, mark it as direct now
        if isDirect && ~isPackageDirectlyImported(packageName)
            markPackageAsDirect(packageName);
            fprintf('Package "%s" is already imported (now marked as direct)\n', packageName);
        else
            fprintf('Package "%s" is already imported\n', packageName);
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
            
            % Import dependencies first
            if isfield(mipConfig, 'dependencies') && ~isempty(mipConfig.dependencies)
                fprintf('Importing dependencies for "%s": %s\n', ...
                        packageName, strjoin(mipConfig.dependencies, ', '));
                for i = 1:length(mipConfig.dependencies)
                    dep = mipConfig.dependencies{i};
                    if ~isPackageImported(dep)
                        mip.import(dep, 'importingStack', importingStack, 'isDirect', false);
                    else
                        fprintf('  Dependency "%s" is already imported\n', dep);
                    end
                end
            end
        catch ME
            warning('mip:jsonParseError', ...
                    'Could not parse mip.json for package "%s": %s', ...
                    packageName, ME.message);
        end
    end
    
    % Look for setup.m file
    setupFile = fullfile(packageDir, 'setup.m');
    if ~exist(setupFile, 'file')
        error('mip:setupNotFound', ...
              'Package "%s" does not have a setup.m file', packageName);
    end
    
    % Execute the setup.m file
    originalDir = pwd;
    cd(packageDir);
    try
        run(setupFile);
        fprintf('Imported package "%s"\n', packageName);
    catch ME
        warning('mip:setupError', ...
                'Error executing setup.m for package "%s": %s', ...
                packageName, ME.message);
    end
    cd(originalDir);
    
    % Mark package as imported
    markPackageAsImported(packageName, isDirect);
    
    % Pin package if requested
    if pinPackage && isDirect
        mip.pin(packageName);
    end
end

function imported = isPackageImported(packageName)
    % Helper function to check if a package has already been imported
    global MIP_IMPORTED_PACKAGES;
    if isempty(MIP_IMPORTED_PACKAGES)
        MIP_IMPORTED_PACKAGES = {};
    end
    imported = ismember(packageName, MIP_IMPORTED_PACKAGES);
end

function markPackageAsImported(packageName, isDirect)
    % Helper function to mark a package as imported
    global MIP_IMPORTED_PACKAGES;
    global MIP_DIRECTLY_IMPORTED_PACKAGES;
    
    if isempty(MIP_IMPORTED_PACKAGES)
        MIP_IMPORTED_PACKAGES = {};
    end
    if ~ismember(packageName, MIP_IMPORTED_PACKAGES)
        MIP_IMPORTED_PACKAGES{end+1} = packageName;
    end
    
    % Track directly imported packages separately
    if isDirect
        markPackageAsDirect(packageName);
    end
end

function markPackageAsDirect(packageName)
    % Helper function to mark a package as directly imported
    global MIP_DIRECTLY_IMPORTED_PACKAGES;
    
    if isempty(MIP_DIRECTLY_IMPORTED_PACKAGES)
        MIP_DIRECTLY_IMPORTED_PACKAGES = {};
    end
    if ~ismember(packageName, MIP_DIRECTLY_IMPORTED_PACKAGES)
        MIP_DIRECTLY_IMPORTED_PACKAGES{end+1} = packageName;
    end
end

function direct = isPackageDirectlyImported(packageName)
    % Helper function to check if a package is directly imported
    global MIP_DIRECTLY_IMPORTED_PACKAGES;
    if isempty(MIP_DIRECTLY_IMPORTED_PACKAGES)
        MIP_DIRECTLY_IMPORTED_PACKAGES = {};
    end
    direct = ismember(packageName, MIP_DIRECTLY_IMPORTED_PACKAGES);
end
