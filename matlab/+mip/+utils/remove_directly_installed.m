function remove_directly_installed(packageName)
%REMOVE_DIRECTLY_INSTALLED   Remove a package from the directly installed list.
%
% Args:
%   packageName - Name of package to remove

    packages = mip.utils.get_directly_installed();
    packages = packages(~strcmp(packages, packageName));
    mip.utils.set_directly_installed(packages);
end
