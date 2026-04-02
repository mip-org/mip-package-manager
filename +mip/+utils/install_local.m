function install_local(sourceDir, editable)
%INSTALL_LOCAL   Install a package from a local directory with mip.yaml.
%
% Args:
%   sourceDir - Path to the directory containing mip.yaml
%   editable  - If true, create an editable install (symlink-style)

if nargin < 2
    editable = false;
end

% Ensure yamlmatlab is available
mip.utils.ensure_yamlmatlab();

% Resolve to absolute path
sourceDir = char(java.io.File(sourceDir).getCanonicalPath());

% Read mip.yaml
mipConfig = mip.utils.read_mip_yaml(sourceDir);
packageName = mipConfig.name;

fprintf('Found package "%s" (version %s)\n', packageName, ...
        num2str(mipConfig.version));

% Use local/local as the org/channel for local installs
org = 'local';
channelName = 'local';
fqn = mip.utils.make_fqn(org, channelName, packageName);

% Check if already installed
pkgDir = mip.utils.get_package_dir(org, channelName, packageName);
if exist(pkgDir, 'dir')
    fprintf('Package "%s" is already installed. Uninstall first to reinstall.\n', fqn);
    return;
end

% Install dependencies if any
if ~isempty(mipConfig.dependencies)
    fprintf('Dependencies: %s\n', strjoin(mipConfig.dependencies, ', '));
    fprintf('Note: dependencies must be installed separately for local packages.\n');
    % Check that dependencies are installed
    for i = 1:length(mipConfig.dependencies)
        dep = mipConfig.dependencies{i};
        depFqn = mip.utils.resolve_bare_name(dep);
        if isempty(depFqn)
            error('mip:dependencyNotFound', ...
                  'Dependency "%s" is not installed. Install it first.', dep);
        end
    end
end

% Compute addpaths from mip.yaml
addpathsList = mip.utils.compute_addpaths(sourceDir, mipConfig.addpaths);

% Create the package directory
parentDir = fileparts(pkgDir);
if ~exist(parentDir, 'dir')
    mkdir(parentDir);
end

if editable
    % Editable install: create a thin wrapper that points to the source
    fprintf('Installing "%s" in editable mode...\n', fqn);
    mkdir(pkgDir);

    % Create load_package.m that adds the SOURCE directory paths
    createLoadScript(pkgDir, sourceDir, addpathsList);
    createUnloadScript(pkgDir, sourceDir, addpathsList);

    % Create mip.json with editable flag and source path
    createMipJson(pkgDir, mipConfig, sourceDir, true);

    fprintf('Editable install complete. Changes in %s will be reflected immediately.\n', sourceDir);
else
    % Regular install: copy package contents to mip packages dir
    fprintf('Installing "%s"...\n', fqn);

    % Copy the entire source directory
    copyfile(sourceDir, pkgDir);

    % Remove .git directory if present
    gitDir = fullfile(pkgDir, '.git');
    if exist(gitDir, 'dir')
        rmdir(gitDir, 's');
    end

    % Create load/unload scripts that reference the installed copy
    createLoadScript(pkgDir, pkgDir, addpathsList);
    createUnloadScript(pkgDir, pkgDir, addpathsList);

    % Create mip.json
    createMipJson(pkgDir, mipConfig, '', false);

    fprintf('Install complete.\n');
end

% Mark as directly installed
mip.utils.add_directly_installed(fqn);
fprintf('Successfully installed "%s"\n', fqn);

end


function createLoadScript(pkgDir, baseDir, addpathsList)
% Create load_package.m

    loadFile = fullfile(pkgDir, 'load_package.m');
    fid = fopen(loadFile, 'w');
    if fid == -1
        error('mip:fileError', 'Could not create load_package.m');
    end

    fprintf(fid, 'function load_package()\n');
    fprintf(fid, '    %% Add package directories to MATLAB path\n');

    for i = 1:length(addpathsList)
        p = addpathsList{i};
        if strcmp(p, '.')
            fprintf(fid, '    addpath(''%s'');\n', baseDir);
        else
            fprintf(fid, '    addpath(fullfile(''%s'', ''%s''));\n', baseDir, p);
        end
    end

    fprintf(fid, 'end\n');
    fclose(fid);
end


function createUnloadScript(pkgDir, baseDir, addpathsList)
% Create unload_package.m

    unloadFile = fullfile(pkgDir, 'unload_package.m');
    fid = fopen(unloadFile, 'w');
    if fid == -1
        error('mip:fileError', 'Could not create unload_package.m');
    end

    fprintf(fid, 'function unload_package()\n');
    fprintf(fid, '    %% Remove package directories from MATLAB path\n');

    for i = 1:length(addpathsList)
        p = addpathsList{i};
        if strcmp(p, '.')
            fprintf(fid, '    rmpath(''%s'');\n', baseDir);
        else
            fprintf(fid, '    rmpath(fullfile(''%s'', ''%s''));\n', baseDir, p);
        end
    end

    fprintf(fid, 'end\n');
    fclose(fid);
end


function createMipJson(pkgDir, mipConfig, sourceDir, isEditable)
% Create mip.json metadata file

    mipData = struct();
    mipData.name = mipConfig.name;
    mipData.version = mipConfig.version;
    mipData.description = mipConfig.description;
    mipData.dependencies = mipConfig.dependencies;
    mipData.license = mipConfig.license;
    mipData.homepage = mipConfig.homepage;
    mipData.repository = mipConfig.repository;
    mipData.architecture = 'any';
    mipData.exposed_symbols = {};
    mipData.install_type = 'local';

    if isEditable
        mipData.editable = true;
        mipData.source_path = sourceDir;
    end

    jsonText = jsonencode(mipData);
    mipJsonPath = fullfile(pkgDir, 'mip.json');
    fid = fopen(mipJsonPath, 'w');
    if fid == -1
        error('mip:fileError', 'Could not create mip.json');
    end
    fwrite(fid, jsonText);
    fclose(fid);
end
