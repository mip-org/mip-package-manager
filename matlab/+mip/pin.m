function pin(packageName)
%PIN   Pin a loaded package to prevent it from being unloaded by 'unload --all'.
%
% Usage:
%   mip.pin('packageName')
%
% This function marks a package as pinned. Pinned packages will not be
% removed when using 'mip unload --all'.

MIP_LOADED_PACKAGES = mip.utils.get_key_value('MIP_LOADED_PACKAGES');
MIP_PINNED_PACKAGES = mip.utils.get_key_value('MIP_PINNED_PACKAGES');

% Check if package is loaded
if ~ismember(packageName, MIP_LOADED_PACKAGES)
    error('mip:pin:packageNotLoaded', ...
          'Package "%s" is not currently loaded. Load it first with "mip load %s".', ...
          packageName, packageName);
end

% Check if already pinned
if ismember(packageName, MIP_PINNED_PACKAGES)
    fprintf('Package "%s" is already pinned\n', packageName);
    return
end

% Add to pinned packages
MIP_PINNED_PACKAGES{end+1} = packageName;
mip.utils.set_key_value('MIP_PINNED_PACKAGES', MIP_PINNED_PACKAGES);
fprintf('Pinned package "%s"\n', packageName);

end
