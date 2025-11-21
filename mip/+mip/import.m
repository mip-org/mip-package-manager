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
    
    % Add to path (current session only)
    addpath(mipDir);
    fprintf('Added "%s" to MATLAB path\n', packageName);
end
