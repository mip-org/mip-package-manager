function import(packageName)
    % import - Import a mip package into MATLAB path
    %
    % Usage:
    %   mip.import('packageName')
    %
    % This function adds the specified package from ~/.mip/packages to the
    % MATLAB path for the current session only.
    
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
    end
    % Return to original directory
    cd(originalDir);
end
