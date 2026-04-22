function fqn = make_local_fqn(packageName)
%MAKE_LOCAL_FQN   Create an FQN for a local directory install.
%
% Args:
%   packageName - Package name
%
% Returns:
%   fqn - Canonical FQN: 'local/name'

fqn = ['local/' packageName];

end
