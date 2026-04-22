function remove_pinned(packageName)
%REMOVE_PINNED   Remove a package from the pinned list.
%
% Args:
%   packageName - FQN of package to unpin (canonical or 3-part shorthand)

    packageName = mip.parse.canonical_fqn(packageName);
    packages = mip.state.get_pinned();
    packages = packages(~strcmp(packages, packageName));
    mip.state.set_pinned(packages);
end
