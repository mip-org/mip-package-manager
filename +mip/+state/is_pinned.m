function tf = is_pinned(packageName)
%IS_PINNED   Check if a package is pinned.
%
% Args:
%   packageName - FQN of package to check (canonical or 3-part shorthand)
%
% Returns:
%   tf - true if the package is pinned

    packageName = mip.parse.canonical_fqn(packageName);
    packages = mip.state.get_pinned();
    tf = ismember(packageName, packages);
end
