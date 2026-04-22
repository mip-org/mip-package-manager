function direct = is_directly_installed(packageName)
%IS_DIRECTLY_INSTALLED   Check if a package is directly installed.
%
% Args:
%   packageName - FQN of package to check (canonical or 3-part shorthand)
%
% Returns:
%   direct - True if package is directly installed

    packageName = mip.parse.canonical_fqn(packageName);
    packages = mip.state.get_directly_installed();
    direct = ismember(packageName, packages);
end
