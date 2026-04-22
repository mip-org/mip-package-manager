function add_directly_installed(packageName)
%ADD_DIRECTLY_INSTALLED   Add a package to the directly installed list.
%
% Args:
%   packageName - FQN of package to add (canonical or 3-part shorthand)

    packageName = mip.parse.canonical_fqn(packageName);
    packages = mip.state.get_directly_installed();

    if ~ismember(packageName, packages)
        packages{end+1} = packageName; %#ok<*AGROW>
        mip.state.set_directly_installed(packages);
    end
end
