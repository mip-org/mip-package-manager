function unpin(package)
%UNPIN   Unpin a package.
%
% Usage:
%   mip.unpin('packageName')
%
% This function removes the pin from a package, allowing it to be unloaded with
% 'mip unload --all'.

% Check if package is pinned
if ~mip.utils.is_pinned(package)
    fprintf('Package "%s" is not currently pinned\n', package);
    return
end

% Remove from pinned packages
mip.utils.key_value_remove('MIP_PINNED_PACKAGES', package);
fprintf('Unpinned package "%s"\n', package);

end
