function load(varargin)
%LOAD   Load one or more mip packages into the MATLAB path.
%
% Usage:
%   mip.load('packageName')
%   mip.load('package1', 'package2', ...)
%   mip.load('packageName', '--sticky')
%   mip.load('packageName', '--install')
%   mip.load('--channel', 'owner/chan', 'packageName', '--install')
%   mip.load('org/channel/packageName')
%
% Accepts both bare package names and fully qualified names (org/channel/package).
% For bare names, resolution priority is:
%   1. mip-org/core
%   2. First alphabetically by org/channel
%
% Options:
%   --sticky        Mark the package(s) as sticky (prevents unload with 'mip unload --all')
%   --install       Automatically install the package(s) if not already installed
%   --channel <c>   Channel to install from when using --install
%   --addpath <rel> Add this source-relative subpath to the MATLAB path AFTER
%                   load_package.m runs. May be repeated. Only valid with a
%                   single positional package; applies only to direct loads
%                   (not transitive dependencies).
%   --rmpath  <rel> Remove this source-relative subpath from the MATLAB path
%                   AFTER load_package.m runs. Same constraints as --addpath.
%   --transitive    (internal) Load as a transitive dependency, not a direct load

    % Parse flags and package names from arguments
    installIfMissing = false;
    stickyPackage = false;
    isDirect = true;
    channel = '';
    addPathRels = {};
    rmPathRels = {};
    packageArgs = {};
    i = 1;
    while i <= length(varargin)
        arg = varargin{i};
        if ischar(arg) && strcmp(arg, '--install')
            installIfMissing = true;
        elseif ischar(arg) && strcmp(arg, '--sticky')
            stickyPackage = true;
        elseif ischar(arg) && strcmp(arg, '--transitive')
            isDirect = false;
        elseif ischar(arg) && strcmp(arg, '--channel')
            if i < length(varargin)
                i = i + 1;
                channel = varargin{i};
            else
                error('mip:load:missingChannel', '--channel requires a value');
            end
        elseif ischar(arg) && strcmp(arg, '--addpath')
            if i < length(varargin)
                i = i + 1;
                addPathRels{end+1} = varargin{i}; %#ok<*AGROW>
            else
                error('mip:load:missingAddpathValue', '--addpath requires a value');
            end
        elseif ischar(arg) && strcmp(arg, '--rmpath')
            if i < length(varargin)
                i = i + 1;
                rmPathRels{end+1} = varargin{i};
            else
                error('mip:load:missingRmpathValue', '--rmpath requires a value');
            end
        elseif ischar(arg) && ~startsWith(arg, '--')
            packageArgs{end+1} = arg;
        end
        i = i + 1;
    end

    if isempty(packageArgs)
        error('mip:noPackage', 'No package specified for load command.');
    end

    if (~isempty(addPathRels) || ~isempty(rmPathRels)) && length(packageArgs) > 1
        error('mip:load:addpathSinglePackage', ...
              ['--addpath / --rmpath require exactly one positional package; ' ...
               'got %d. The flags resolve relative to that package''s source ' ...
               'directory.'], length(packageArgs));
    end

    % Load each package. --addpath/--rmpath only flow into direct loads;
    % they are intentionally not propagated to transitive dependencies.
    for i = 1:length(packageArgs)
        if isDirect
            loadSingle(packageArgs{i}, installIfMissing, stickyPackage, ...
                       channel, isDirect, {}, addPathRels, rmPathRels);
        else
            loadSingle(packageArgs{i}, installIfMissing, stickyPackage, ...
                       channel, isDirect, {}, {}, {});
        end
    end
end

function loadSingle(packageArg, installIfMissing, stickyPackage, channel, isDirect, loadingStack, addPathRels, rmPathRels)
% Load a single package (and its dependencies recursively).
%
% addPathRels / rmPathRels: cell arrays of source-relative paths to
% addpath / rmpath after load_package.m runs. Only honored for direct
% loads (the recursive call for dependencies passes empty).

    % Resolve the FQN for this package, installing first if requested
    try
        fqn = resolveToFqn(packageArg);
    catch ME
        if installIfMissing && strcmp(ME.identifier, 'mip:packageNotFound')
            fprintf('Package "%s" is not installed. Installing...\n', packageArg);
            if ~isempty(channel)
                mip.install('--channel', channel, packageArg);
            else
                mip.install(packageArg);
            end
            fqn = resolveToFqn(packageArg);
        else
            rethrow(ME);
        end
    end

    % mip-org/core/mip is always loaded — nothing to do
    if strcmp(fqn, 'mip-org/core/mip')
        fprintf('Package "mip" is always loaded\n');
        return
    end

    % Check for circular dependencies
    if ismember(fqn, loadingStack)
        cycle = strjoin([loadingStack, {fqn}], ' -> ');
        error('mip:circularDependency', ...
              'Circular dependency detected: %s', cycle);
    end

    % Add to loading stack for circular dependency detection
    loadingStack = [loadingStack, {fqn}];

    % Parse FQN to get package directory
    result = mip.parse.parse_package_arg(fqn);
    packageDir = mip.paths.get_package_dir(result.org, result.channel, result.name);

    % Check if package exists
    if ~mip.state.is_installed(fqn)
        error('mip:packageNotFound', ...
              'Package "%s" is not installed. Run "mip install %s" first.', ...
              fqn, fqn);
    end

    % Check if package is already loaded
    if mip.state.is_loaded(fqn)
        % If this is a direct load and the package was previously
        % loaded as a dependency, mark it as direct now
        if isDirect && ~mip.state.is_directly_loaded(fqn)
            mip.state.key_value_append('MIP_DIRECTLY_LOADED_PACKAGES', fqn);
            fprintf('Package "%s" is already loaded (now marked as direct)\n', fqn);
        else
            fprintf('Package "%s" is already loaded\n', fqn);
        end
        % If --sticky was specified, add to sticky packages
        if stickyPackage
            if ~mip.state.is_sticky(fqn)
                mip.state.key_value_append('MIP_STICKY_PACKAGES', fqn);
                fprintf('Package "%s" is now sticky\n', fqn);
            end
        end
        % Apply --addpath/--rmpath even when already loaded so the user
        % can adjust the path of an existing load without re-loading.
        applyPathAdjustments(packageDir, addPathRels, rmPathRels);
        return
    end

    % Load dependencies listed in mip.json. Only the parse step is
    % wrapped in try/catch so that recursive dependency-load errors propagate
    % instead of being silently downgraded to a warning.
    mipJsonPath = fullfile(packageDir, 'mip.json');
    deps = {};
    mipConfig = [];
    if exist(mipJsonPath, 'file')
        try
            mipConfig = mip.config.read_package_json(packageDir);
            deps = mipConfig.dependencies;
        catch ME
            warning('mip:jsonParseError', ...
                    'Could not parse mip.json for package "%s": %s', ...
                    fqn, ME.message);
        end
    end

    if ~isempty(deps)
        fprintf('Loading dependencies for "%s": %s\n', ...
                fqn, strjoin(deps, ', '));
        for i = 1:length(deps)
            dep = deps{i};
            depFqn = mip.resolve.resolve_dependency(dep);
            if ~mip.state.is_loaded(depFqn)
                loadSingle(depFqn, installIfMissing, false, channel, false, loadingStack, {}, {});
            else
                fprintf('  Dependency "%s" is already loaded\n', depFqn);
            end
        end
    end

    % Add paths from mip.json (new-style packages). Legacy packages that
    % predate the paths field omit it entirely; they rely on
    % load_package.m below instead.
    hasPathsField = ~isempty(mipConfig) && isfield(mipConfig, 'paths');
    if hasPathsField
        applyMipJsonPaths(packageDir, mipConfig);
    end

    % Look for load_package.m file (legacy support; also allowed alongside
    % the paths field for packages that need custom init logic).
    loadFile = fullfile(packageDir, 'load_package.m');
    hasLoadScript = exist(loadFile, 'file') ~= 0;

    if ~hasPathsField && ~hasLoadScript
        error('mip:loadNotFound', ...
              ['Package "%s" has no "paths" field in mip.json and no ' ...
               'load_package.m file'], fqn);
    end

    % Execute the load_package.m file. If it errors, the package is NOT
    % marked as loaded, so the user can fix the issue and retry. We do not
    % attempt to roll back any path or state changes that load_package.m
    % (or the paths field above) may have made before failing -- doing so
    % reliably is not possible.
    if hasLoadScript
        originalDir = pwd;
        restoreDir = onCleanup(@() cd(originalDir));
        cd(packageDir);
        try
            run(loadFile);
        catch ME
            loadErr = MException('mip:loadError', ...
                'Error executing load_package.m for package "%s": %s', ...
                fqn, ME.message);
            loadErr = addCause(loadErr, ME);
            throw(loadErr);
        end
        clear restoreDir;
    end
    fprintf('Loaded package "%s"\n', fqn);

    % Apply --addpath / --rmpath after load_package.m has run.
    applyPathAdjustments(packageDir, addPathRels, rmPathRels);

    % Mark package as loaded
    mip.state.key_value_append('MIP_LOADED_PACKAGES', fqn);

    % Track directly loaded packages separately
    if isDirect
        mip.state.key_value_append('MIP_DIRECTLY_LOADED_PACKAGES', fqn);
    end

    % Mark package as sticky if requested
    if stickyPackage
        mip.state.key_value_append('MIP_STICKY_PACKAGES', fqn);
        fprintf('Package "%s" is now sticky\n', fqn);
    end
end

function applyMipJsonPaths(packageDir, pkgInfo)
% addpath each entry in pkgInfo.paths against the package source
% directory. Silent on success -- the "Loaded package" summary is
% printed by the caller.
    if isempty(pkgInfo.paths)
        return
    end
    srcDir = mip.paths.get_source_dir(packageDir, pkgInfo);
    for i = 1:length(pkgInfo.paths)
        rel = pkgInfo.paths{i};
        if strcmp(rel, '.')
            target = srcDir;
        else
            target = fullfile(srcDir, rel);
        end
        addpath(target);
    end
end

function applyPathAdjustments(packageDir, addPathRels, rmPathRels)
% Apply --addpath / --rmpath relative to the package's source directory.
% No-op if both lists are empty.

    if isempty(addPathRels) && isempty(rmPathRels)
        return
    end

    pkgInfo = mip.config.read_package_json(packageDir);
    srcDir = mip.paths.get_source_dir(packageDir, pkgInfo);

    for i = 1:length(addPathRels)
        rel = addPathRels{i};
        target = fullfile(srcDir, rel);
        % addpath emits MATLAB:addpath:DirNotFound if the target is missing.
        addpath(target);
        fprintf('  +addpath %s\n', target);
    end

    for i = 1:length(rmPathRels)
        rel = rmPathRels{i};
        target = fullfile(srcDir, rel);
        % rmpath warns (not errors) if the path is not on the search path.
        rmpath(target);
        fprintf('  -rmpath %s\n', target);
    end
end

function fqn = resolveToFqn(packageArg)
% Resolve a package argument to a fully qualified name.
% If already FQN, canonicalize the name component to its on-disk form.
% If bare name, look up installed packages.

    result = mip.parse.parse_package_arg(packageArg);

    if result.is_fqn
        % Canonicalize: find the actual on-disk name (case- and
        % dash/underscore-insensitive) so the rest of load uses the
        % canonical form, matching what's already in the loaded/sticky
        % state lists.
        onDisk = mip.resolve.installed_dir(result.org, result.channel, result.name);
        if isempty(onDisk)
            error('mip:packageNotFound', ...
                  'Package "%s" is not installed. Run "mip install %s" first.', ...
                  packageArg, packageArg);
        end
        fqn = mip.parse.make_fqn(result.org, result.channel, onDisk);
    else
        % Resolve bare name to installed FQN
        fqn = mip.resolve.resolve_bare_name(result.name);
        if isempty(fqn)
            error('mip:packageNotFound', ...
                  'Package "%s" is not installed. Run "mip install %s" first.', ...
                  result.name, result.name);
        end
    end
end

