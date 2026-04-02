function [org, channelName] = parse_channel_spec(channel)
%PARSE_CHANNEL_SPEC   Parse a channel string into org and channel name.
%
% Args:
%   channel - Channel string: 'core', 'dev', 'owner/chan', or empty
%
% Returns:
%   org         - Organization name (e.g. 'mip-org', 'mylab')
%   channelName - Channel name (e.g. 'core', 'dev', 'custom')
%
% Examples:
%   [org, ch] = parse_channel_spec('')           % -> 'mip-org', 'core'
%   [org, ch] = parse_channel_spec('core')       % -> 'mip-org', 'core'
%   [org, ch] = parse_channel_spec('dev')        % -> 'mip-org', 'dev'
%   [org, ch] = parse_channel_spec('mylab/custom') % -> 'mylab', 'custom'

if nargin < 1 || isempty(channel)
    channel = 'core';
end

parts = strsplit(channel, '/');

if length(parts) == 1
    % Simple channel name like 'core' or 'dev' -> default org is mip-org
    org = 'mip-org';
    channelName = parts{1};
elseif length(parts) == 2
    % owner/channel format
    org = parts{1};
    channelName = parts{2};
else
    error('mip:invalidChannel', ...
          'Invalid channel format "%s". Use "channel" or "owner/channel".', channel);
end

end
