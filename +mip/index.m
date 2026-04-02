function url = index(channel)
%INDEX   Get the URL for the mip package index.
%
% Usage:
%   url = mip.index()                  - Get URL for default channel (core)
%   url = mip.index('dev')             - Get URL for named channel
%   url = mip.index('owner/channel')   - Get URL for a user-hosted channel
%
% Channel URL mapping:
%   'core'           -> https://mip-org.github.io/mip-core/index.json
%   'dev'            -> https://mip-org.github.io/mip-dev/index.json
%   'owner/channel'  -> https://owner.github.io/mip-channel/index.json

if nargin < 1 || isempty(channel)
    channel = 'core';
end

[org, channelName] = mip.utils.parse_channel_spec(channel);

url = sprintf('https://%s.github.io/mip-%s/index.json', org, channelName);

end
