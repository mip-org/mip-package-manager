function find_name_collisions()
%FIND_NAME_COLLISIONS   Find symbol name collisions across installed packages.
%
% Usage:
%   mip.find_name_collisions()
%
% Scans all installed packages and reports any function or class names
% that appear in multiple packages, which could cause conflicts when
% packages are loaded simultaneously.

allPackages = mip.utils.list_installed_packages();

if isempty(allPackages)
    fprintf('No packages installed yet\n');
    return
end

% Dictionary to track symbols: symbol_name -> {list of FQNs}
symbolToPackages = containers.Map('KeyType', 'char', 'ValueType', 'any');
% Dictionary to track symbol counts per package
packageSymbolCounts = containers.Map('KeyType', 'char', 'ValueType', 'double');

fprintf('Scanning installed packages for exposed symbols...\n');
fprintf('\n');

% Scan all installed packages
for i = 1:length(allPackages)
    fqn = allPackages{i};
    result = mip.utils.parse_package_arg(fqn);
    pkgDir = mip.utils.get_package_dir(result.org, result.channel, result.name);

    try
        pkgInfo = mip.utils.read_package_json(pkgDir);
        exposedSymbols = pkgInfo.exposed_symbols;

        if ~iscell(exposedSymbols)
            exposedSymbols = {};
        end

        packageSymbolCounts(fqn) = length(exposedSymbols);

        for j = 1:length(exposedSymbols)
            symbol = exposedSymbols{j};
            if symbolToPackages.isKey(symbol)
                pkgList = symbolToPackages(symbol);
            else
                pkgList = {};
            end
            symbolToPackages(symbol) = [pkgList, {fqn}];
        end

    catch
        packageSymbolCounts(fqn) = 0;
    end
end

% Print symbol counts per package
fprintf('Exposed symbols per package:\n');
for i = 1:length(allPackages)
    fqn = allPackages{i};
    if packageSymbolCounts.isKey(fqn)
        count = packageSymbolCounts(fqn);
    else
        count = 0;
    end
    fprintf('  - %s: %d symbol(s)\n', fqn, count);
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
