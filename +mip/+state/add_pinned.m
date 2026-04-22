function add_pinned(packageName)
%ADD_PINNED   Add a package to the pinned list.
%
% Args:
%   packageName - FQN of package to pin (canonical or 3-part shorthand)

    packageName = mip.parse.canonical_fqn(packageName);
    packages = mip.state.get_pinned();

    if ~ismember(packageName, packages)
        packages{end+1} = packageName;
        mip.state.set_pinned(packages);
    end
end
