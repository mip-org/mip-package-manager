function unpin(packageName)
%UNPIN   Unpin a package.
%
% Usage:
%   mip.unpin('packageName')
%
% This function removes the pin from a package, allowing it to be unloaded with
% 'mip unload --all'.

MIP_PINNED_PACKAGES = mip.utils.get_key_value('MIP_PINNED_PACKAGES');

% Check if package is pinned
if ~ismember(packageName, MIP_PINNED_PACKAGES)
    fprintf('Package "%s" is not currently pinned\n', packageName);
    return
end

% Remove from pinned packages
MIP_PINNED_PACKAGES = MIP_PINNED_PACKAGES(    ...
    ~strcmp(MIP_PINNED_PACKAGES, packageName) ...
);
mip.utils.set_key_value('MIP_PINNED_PACKAGES', MIP_PINNED_PACKAGES);
fprintf('Unpinned package "%s"\n', packageName);

end
