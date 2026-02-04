function find_name_collisions()
%FIND_NAME_COLLISIONS   Find symbol name collisions across installed packages.
%
% Usage:
%   mip.find_name_collisions()
%
% Scans all installed packages and reports any function or class names
% that appear in multiple packages, which could cause conflicts when
% packages are loaded simultaneously.
%
% Example:
%   mip.find_name_collisions()

packagesDir = mip.utils.get_packages_dir();

if ~exist(packagesDir, 'dir')
    fprintf('No packages installed yet\n');
    return
end

% Dictionary to track symbols: symbol_name -> {list of packages}
symbolToPackages = containers.Map('KeyType', 'char', 'ValueType', 'any');
% Dictionary to track symbol counts per package
packageSymbolCounts = containers.Map('KeyType', 'char', 'ValueType', 'double');

fprintf('Scanning installed packages for exposed symbols...\n');
fprintf('\n');

% Get all package directories
dirContents = dir(packagesDir);
packages = {};

for i = 1:length(dirContents)
    if dirContents(i).isdir && ~startsWith(dirContents(i).name, '.')
        packages = [packages, {dirContents(i).name}]; %#ok<AGROW>
    end
end

if isempty(packages)
    fprintf('No packages installed yet\n');
    return
end

packages = sort(packages);

% Scan all installed packages
for i = 1:length(packages)
    packageName = packages{i};
    pkgDir = fullfile(packagesDir, packageName);
    
    % Read mip.json if it exists
    try
        pkgInfo = mip.utils.read_package_json(pkgDir);
        exposedSymbols = pkgInfo.exposed_symbols;

        if ~iscell(exposedSymbols)
            exposedSymbols = {};
        end

        % Track count for this package
        packageSymbolCounts(packageName) = length(exposedSymbols);

        % Track which packages expose each symbol
        for j = 1:length(exposedSymbols)
            symbol = exposedSymbols{j};
            if symbolToPackages.isKey(symbol)
                pkgList = symbolToPackages(symbol);
            else
                pkgList = {};
            end
            symbolToPackages(symbol) = [pkgList, {packageName}];
        end

    catch
        % If can't read mip.json, assume no exposed symbols
        packageSymbolCounts(packageName) = 0;
    end
end

% Print symbol counts per package
fprintf('Exposed symbols per package:\n');
for i = 1:length(packages)
    packageName = packages{i};
    if packageSymbolCounts.isKey(packageName)
        count = packageSymbolCounts(packageName);
    else
        count = 0;
    end
    fprintf('  - %s: %d symbol(s)\n', packageName, count);
end

fprintf('\n');

% Find collisions (symbols in more than one package)
collisions = containers.Map('KeyType', 'char', 'ValueType', 'any');
symbolNames = keys(symbolToPackages);

for i = 1:length(symbolNames)
    symbol = symbolNames{i};
    pkgList = symbolToPackages(symbol);
    if length(pkgList) > 1
        collisions(symbol) = pkgList;
    end
end

if collisions.Count == 0
    fprintf('No name collisions found\n');
else
    fprintf('Name collisions found: %d\n', collisions.Count);
    fprintf('\n');
    fprintf('Colliding symbols:\n');
    collisionSymbols = sort(keys(collisions));
    for i = 1:length(collisionSymbols)
        symbol = collisionSymbols{i};
        pkgList = collisions(symbol);
        fprintf('  - %s (found in: %s)\n', symbol, strjoin(pkgList, ', '));
    end
end

end
