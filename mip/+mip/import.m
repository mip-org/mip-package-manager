function import(packageName, varargin)
    % import - Import a mip package into MATLAB path
    %
    % Usage:
    %   mip.import('packageName')
    %
    % This function adds the specified package from ~/.mip/packages to the
    % MATLAB path for the current session only.
    
    % Parse optional arguments for internal use
    p = inputParser;
    addParameter(p, 'importingStack', {}, @iscell);
    parse(p, varargin{:});
    importingStack = p.Results.importingStack;
    
    % Check for circular dependencies
    if ismember(packageName, importingStack)
        cycle = strjoin([importingStack, {packageName}], ' -> ');
        error('mip:circularDependency', ...
              'Circular dependency detected: %s', cycle);
    end
    
    % Add to importing stack for circular dependency detection
    importingStack = [importingStack, {packageName}];
    
    % Get the mip packages directory
    homeDir = getenv('HOME');
    if isempty(homeDir)
        % Windows fallback
        homeDir = getenv('USERPROFILE');
    end
    
    mipDir = fullfile(homeDir, '.mip', 'packages', packageName);
    
    % Check if package exists
    if ~exist(mipDir, 'dir')
        error('mip:packageNotFound', ...
              'Package "%s" is not installed. Run "mip install %s" first.', ...
              packageName, packageName);
    end
    
    % Check if there's a single nested directory (common in GitHub zips)
    % If so, use that directory instead of the top level
    contents = dir(mipDir);
    contents = contents(~ismember({contents.name}, {'.', '..'}));
    
    if length(contents) == 1 && contents(1).isdir
        % There's a single subdirectory, use that as the actual package path
        actualPackageDir = fullfile(mipDir, contents(1).name);
    else
        % Use the directory as-is
        actualPackageDir = mipDir;
    end
    
    % Check for mip.json and process dependencies
    mipJsonPath = fullfile(actualPackageDir, 'mip.json');
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
                    % Check if already on path to avoid duplicate imports
                    if ~isPackageOnPath(dep)
                        mip.import(dep, 'importingStack', importingStack);
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
    
    % Check if package is already on path
    if isPackageOnPath(packageName)
        fprintf('Package "%s" is already imported\n', packageName);
        return;
    end
    
    % Add to path (current session only)
    addpath(actualPackageDir);
    fprintf('Added "%s" to MATLAB path\n', actualPackageDir);

    % Check for a setup.m file
    % If it exists, change to that directory, run setup, then return
    setupFile = fullfile(actualPackageDir, 'setup.m');
    if exist(setupFile, 'file')
        originalDir = pwd;
        cd(actualPackageDir);
        try
            setup;  % Call the setup function
            fprintf('Executed setup.m for package "%s"\n', packageName);
        catch ME
            warning('mip:setupError', ...
                    'Error executing setup.m for package "%s": %s', ...
                    packageName, ME.message);
        end
        cd(originalDir);
    end
end

function onPath = isPackageOnPath(packageName)
    % Helper function to check if a package is already on the MATLAB path
    homeDir = getenv('HOME');
    if isempty(homeDir)
        homeDir = getenv('USERPROFILE');
    end
    
    mipDir = fullfile(homeDir, '.mip', 'packages', packageName);
    
    % Check if package exists
    if ~exist(mipDir, 'dir')
        onPath = false;
        return;
    end
    
    % Check for nested directory structure
    contents = dir(mipDir);
    contents = contents(~ismember({contents.name}, {'.', '..'}));
    
    if length(contents) == 1 && contents(1).isdir
        actualPackageDir = fullfile(mipDir, contents(1).name);
    else
        actualPackageDir = mipDir;
    end
    
    % Check if this directory is on the path
    pathDirs = strsplit(path, pathsep);
    onPath = any(strcmp(actualPackageDir, pathDirs));
end
