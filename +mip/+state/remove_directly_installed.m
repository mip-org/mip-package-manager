function remove_directly_installed(packageName)
%REMOVE_DIRECTLY_INSTALLED   Remove a package from the directly installed list.
%
% Args:
%   packageName - FQN of package to remove (canonical or 3-part shorthand)

    packageName = mip.parse.canonical_fqn(packageName);
    packages = mip.state.get_directly_installed();
    packages = packages(~strcmp(packages, packageName));
    mip.state.set_directly_installed(packages);
end
