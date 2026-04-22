function installed = is_installed(fqn)
%IS_INSTALLED   Check if a package is installed.
%
% Args:
%   fqn - FQN (canonical or 3-part shorthand, e.g.
%         'gh/mip-org/core/chebfun', 'mip-org/core/chebfun',
%         'local/mypkg', 'fex/mypkg')
%
% Returns:
%   installed - True if the package directory exists

fqn = mip.parse.canonical_fqn(fqn);
packageDir = mip.paths.get_package_dir(fqn);
installed = exist(packageDir, 'dir') ~= 0;

end
