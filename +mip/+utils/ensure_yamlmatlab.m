function ensure_yamlmatlab()
%ENSURE_YAMLMATLAB   Add yamlmatlab to the MATLAB path if not already present.
%
% Looks for the yamlmatlab library in external/yamlmatlab relative to the
% mip-package-manager root (two levels above the +mip package directory).

if exist('yaml.ReadYaml', 'file')
    return;
end

% Navigate from +mip/+utils/ up to the repo root
thisDir = fileparts(mfilename('fullpath'));   % +mip/+utils
mipPkgDir = fileparts(thisDir);              % +mip
pmRoot = fileparts(mipPkgDir);               % repo root

yamlPath = fullfile(pmRoot, 'external', 'yamlmatlab');
if exist(yamlPath, 'dir')
    addpath(yamlPath);
    return;
end

% Also check relative to the installed package location
% (when mip is installed in ~/.mip/packages/...)
% In that case yamlmatlab won't be there, so check MIP_ROOT
mipRoot = mip.root();
yamlPath2 = fullfile(mipRoot, 'external', 'yamlmatlab');
if exist(yamlPath2, 'dir')
    addpath(yamlPath2);
    return;
end

error('mip:yamlmatlabNotFound', ...
      'yamlmatlab library not found. Needed for reading mip.yaml files.');

end
