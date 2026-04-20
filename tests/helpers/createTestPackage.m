function pkgDir = createTestPackage(rootDir, org, channel, pkgName, varargin)
%CREATETESTPACKAGE   Create a fake installed mip package for testing.
%
% Args:
%   rootDir  - The MIP_ROOT directory (e.g. tempdir)
%   org      - Organization name (e.g. 'mip-org')
%   channel  - Channel name (e.g. 'core')
%   pkgName  - Package name (e.g. 'testpkg')
%
% Optional name-value pairs:
%   'version'      - Version string (default: '1.0.0')
%   'dependencies' - Cell array of dependency names (default: {})
%   'sourceSubdir' - If true, create a pkgDir/<pkgName>/ source subdir
%                    (matches mip's real non-editable install layout) and
%                    have load/unload_package.m target that subdir. Required
%                    for tests that exercise mip.paths.get_source_dir.
%                    Default: false (source lives at pkgDir top level).
%   'subdirs'      - Cell array of source-relative subdirs to mkdir under
%                    the effective source directory (default: {}).
%   'style'        - Controls which load/unload mechanism is emitted:
%                      'legacy' - only load_package.m / unload_package.m
%                      'new'    - only "paths" field in mip.json (no scripts)
%                      'both'   - both (default). For sourceSubdir=false the
%                                 flat layout has no realistic source dir, so
%                                 'both' falls back to legacy-only.

p = inputParser;
addParameter(p, 'version', '1.0.0', @ischar);
addParameter(p, 'dependencies', {}, @iscell);
addParameter(p, 'sourceSubdir', false, @islogical);
addParameter(p, 'subdirs', {}, @iscell);
addParameter(p, 'style', 'both', @(s) ischar(s) && ismember(s, {'legacy', 'new', 'both'}));
parse(p, varargin{:});

pkgDir = fullfile(rootDir, 'packages', org, channel, pkgName);
style = p.Results.style;
useSourceSubdir = p.Results.sourceSubdir;

% Create directory tree
if ~exist(pkgDir, 'dir')
    mkdir(pkgDir);
end

if useSourceSubdir
    sourceDir = fullfile(pkgDir, pkgName);
    if ~exist(sourceDir, 'dir')
        mkdir(sourceDir);
    end
else
    sourceDir = pkgDir;
end

for i = 1:numel(p.Results.subdirs)
    mkdir(fullfile(sourceDir, p.Results.subdirs{i}));
end

% The "paths" field in mip.json only makes sense when the package has a
% real source subdir that mip.paths.get_source_dir can return. Flat test
% layouts (sourceSubdir=false) don't, so 'both' and 'new' fall back to
% legacy-only there. Callers that need the new-style behavior on a flat
% layout should pass sourceSubdir=true.
emitPathsField = useSourceSubdir && ismember(style, {'new', 'both'});
emitLegacyScripts = ~useSourceSubdir || ismember(style, {'legacy', 'both'});

% Create mip.json
mipData = struct();
mipData.name = pkgName;
mipData.version = p.Results.version;
mipData.description = ['Test package ' pkgName];
mipData.architecture = 'any';
mipData.install_type = 'test';

deps = p.Results.dependencies;
if isempty(deps)
    mipData.dependencies = reshape({}, 0, 1);
else
    mipData.dependencies = deps;
end

if emitPathsField
    mipData.paths = {'.'};
end

fid = fopen(fullfile(pkgDir, 'mip.json'), 'w');
fwrite(fid, jsonencode(mipData));
fclose(fid);

if ~emitLegacyScripts
    return
end

% Build load/unload scripts. When sourceSubdir is set, target pkgDir/<name>/;
% otherwise target pkgDir itself.
if useSourceSubdir
    targetExpr = sprintf('fullfile(pkg_dir, ''%s'')', pkgName);
else
    targetExpr = 'pkg_dir';
end

fid = fopen(fullfile(pkgDir, 'load_package.m'), 'w');
fprintf(fid, 'function load_package()\n');
fprintf(fid, '    pkg_dir = fileparts(mfilename(''fullpath''));\n');
fprintf(fid, '    addpath(%s);\n', targetExpr);
fprintf(fid, 'end\n');
fclose(fid);

fid = fopen(fullfile(pkgDir, 'unload_package.m'), 'w');
fprintf(fid, 'function unload_package()\n');
fprintf(fid, '    pkg_dir = fileparts(mfilename(''fullpath''));\n');
fprintf(fid, '    target = %s;\n', targetExpr);
fprintf(fid, '    if ismember(target, strsplit(path, pathsep))\n');
fprintf(fid, '        rmpath(target);\n');
fprintf(fid, '    end\n');
fprintf(fid, 'end\n');
fclose(fid);

end
