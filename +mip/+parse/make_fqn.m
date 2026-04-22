function fqn = make_fqn(org, channelName, packageName)
%MAKE_FQN   Create a fully qualified GitHub-channel package name.
%
% GitHub-hosted channel packages live under the 'gh/' source-type
% prefix on disk and in canonical FQNs.
%
% Args:
%   org         - Organization name (e.g. 'mip-org')
%   channelName - Channel name (e.g. 'core')
%   packageName - Package name (e.g. 'chebfun')
%
% Returns:
%   fqn - Canonical FQN: 'gh/org/channel/name'

fqn = ['gh/' org '/' channelName '/' packageName];

end
