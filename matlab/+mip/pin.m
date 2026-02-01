function pin(package)
%PIN   Pin a loaded package to prevent it from being unloaded by 'unload --all'.
%
% Usage:
%   mip.pin('package')
%
% This function marks a package as pinned. Pinned packages will not be
% removed when using 'mip unload --all'.

% Check if package is loaded
if ~mip.utils.is_loaded(package)
    error('mip:pin:packageNotLoaded', ...
          'Package "%s" is not currently loaded. Load it first with "mip load %s".', ...
          package, package);
end

% Check if already pinned
if mip.utils.is_pinned(package)
    fprintf('Package "%s" is already pinned\n', package);
    return
end

% Add to pinned packages
mip.utils.key_value_append('MIP_PINNED_PACKAGES', package);
fprintf('Pinned package "%s"\n', package);

end
