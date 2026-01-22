function package_info(packageName)
    % PACKAGE_INFO Display detailed information about a package
    %
    % Usage:
    %   mip.package_info('packageName')
    %
    % Args:
    %   packageName - Name of the package to display information for
    %
    % Displays detailed information about an installed package including
    % name, version, dependencies, exposed symbols, and installation path.
    %
    % Example:
    %   mip.package_info('chebfun')
    
    if nargin < 1
        error('mip:noPackage', 'Package name is required');
    end
    
    if isstring(packageName)
        packageName = char(packageName);
    end
    
    packagesDir = mip.utils.get_packages_dir();
    pkgDir = fullfile(packagesDir, packageName);
    
    if ~exist(pkgDir, 'dir')
        error('mip:packageNotInstalled', ...
              'Package "%s" is not installed', packageName);
    end
    
    try
        pkgInfo = mip.utils.read_package_json(pkgDir);
        
        fprintf('\n');
        fprintf('=== Package Information ===\n\n');
        fprintf('Name: %s\n', pkgInfo.name);
        
        if isfield(pkgInfo, 'version')
            fprintf('Version: %s\n', pkgInfo.version);
        end
        
        fprintf('Installation Path: %s\n', pkgDir);
        
        if isfield(pkgInfo, 'dependencies') && ~isempty(pkgInfo.dependencies)
            fprintf('\nDependencies:\n');
            deps = pkgInfo.dependencies;
            if ~iscell(deps)
                deps = {deps};
            end
            for i = 1:length(deps)
                fprintf('  - %s\n', deps{i});
            end
        else
            fprintf('\nDependencies: None\n');
        end
        
        if isfield(pkgInfo, 'exposed_symbols') && ~isempty(pkgInfo.exposed_symbols)
            symbols = pkgInfo.exposed_symbols;
            if ~iscell(symbols)
                symbols = {symbols};
            end
            fprintf('\nExposed Symbols (%d):\n', length(symbols));
            for i = 1:min(10, length(symbols))
                fprintf('  - %s\n', symbols{i});
            end
            if length(symbols) > 10
                fprintf('  ... and %d more\n', length(symbols) - 10);
            end
        else
            fprintf('\nExposed Symbols: None listed\n');
        end
        
        fprintf('\n');
        
    catch ME
        if strcmp(ME.identifier, 'mip:packageNotInstalled')
            rethrow(ME);
        else
            error('mip:infoFailed', ...
                  'Failed to read package information: %s', ME.message);
        end
    end
end
