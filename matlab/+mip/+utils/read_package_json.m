function pkgInfo = read_package_json(packageDir)
    % READ_PACKAGE_JSON Read and parse a package's mip.json file
    %
    % Args:
    %   packageDir - Path to the package directory containing mip.json
    %
    % Returns:
    %   pkgInfo - Struct containing package metadata with fields:
    %             name, version, dependencies, exposed_symbols, etc.
    %
    % Example:
    %   info = mip.utils.read_package_json('/path/to/package');
    %   fprintf('Package: %s v%s\n', info.name, info.version);
    
    mipJsonPath = fullfile(packageDir, 'mip.json');
    
    if ~exist(mipJsonPath, 'file')
        error('mip:mipJsonNotFound', ...
              'mip.json not found in package directory: %s', packageDir);
    end
    
    try
        % Read file contents
        jsonText = fileread(mipJsonPath);
        
        % Parse JSON
        pkgInfo = jsondecode(jsonText);
        
        % Ensure required fields exist with defaults
        if ~isfield(pkgInfo, 'name')
            error('mip:invalidMipJson', ...
                  'mip.json is missing required "name" field');
        end
        
        if ~isfield(pkgInfo, 'version')
            pkgInfo.version = 'unknown';
        end
        
        if ~isfield(pkgInfo, 'dependencies')
            pkgInfo.dependencies = {};
        elseif isempty(pkgInfo.dependencies) || (isnumeric(pkgInfo.dependencies) && isempty(pkgInfo.dependencies))
            % jsondecode returns 0x0 double for empty JSON arrays
            pkgInfo.dependencies = {};
        elseif ~iscell(pkgInfo.dependencies)
            % Convert to cell array if needed
            pkgInfo.dependencies = {pkgInfo.dependencies};
        end
        
        if ~isfield(pkgInfo, 'exposed_symbols')
            pkgInfo.exposed_symbols = {};
        elseif isempty(pkgInfo.exposed_symbols) || (isnumeric(pkgInfo.exposed_symbols) && isempty(pkgInfo.exposed_symbols))
            % jsondecode returns 0x0 double for empty JSON arrays
            pkgInfo.exposed_symbols = {};
        elseif ~iscell(pkgInfo.exposed_symbols)
            % Convert to cell array if needed
            pkgInfo.exposed_symbols = {pkgInfo.exposed_symbols};
        end
        
    catch ME
        if strcmp(ME.identifier, 'mip:invalidMipJson')
            rethrow(ME);
        else
            error('mip:jsonParseFailed', ...
                  'Failed to parse mip.json in %s: %s', packageDir, ME.message);
        end
    end
end
