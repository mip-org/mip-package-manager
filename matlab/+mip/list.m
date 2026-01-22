function list()
    % LIST List all installed mip packages
    %
    % Usage:
    %   mip.list()
    %
    % Displays all currently installed packages with their versions.
    %
    % Example:
    %   mip.list()
    %   % Output:
    %   % Installed packages:
    %   %   - chebfun (5.7.0)
    %   %   - package1 (1.2.3)
    
    packagesDir = mip.utils.get_packages_dir();
    
    if ~exist(packagesDir, 'dir')
        fprintf('No packages installed yet\n');
        return;
    end
    
    % Get list of package directories
    dirContents = dir(packagesDir);
    packages = {};
    
    for i = 1:length(dirContents)
        if dirContents(i).isdir && ~startsWith(dirContents(i).name, '.')
            packages = [packages, {dirContents(i).name}]; %#ok<AGROW>
        end
    end
    
    if isempty(packages)
        fprintf('No packages installed yet\n');
        return;
    end
    
    % Sort packages alphabetically
    packages = sort(packages);
    
    % Display packages with versions
    fprintf('Installed packages:\n');
    for i = 1:length(packages)
        pkgName = packages{i};
        pkgDir = fullfile(packagesDir, pkgName);
        
        % Try to read version from mip.json
        version = 'unknown';
        try
            pkgInfo = mip.utils.read_package_json(pkgDir);
            if isfield(pkgInfo, 'version')
                version = pkgInfo.version;
            end
        catch
            % Ignore errors reading mip.json
        end
        
        % Display package with version
        fprintf('  - %s (%s)\n', pkgName, version);
    end
end
