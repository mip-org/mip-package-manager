function url = index_url(channel)
%INDEX_URL   Build the URL for a channel's package index.
%
% Usage:
%   url = mip.channel.index_url()                    - URL for default channel (mip-org/core)
%   url = mip.channel.index_url('owner/channel')     - URL for a user-hosted channel
%   url = mip.channel.index_url('<name>')            - Shorthand for '<name>/<name>'
%
% Channel URL mapping:
%   'mip-org/core'   -> https://mip-org.github.io/mip-core/index.json
%   'owner/channel'  -> https://owner.github.io/mip-channel/index.json
%   '<name>'         -> https://<name>.github.io/mip-<name>/index.json

if nargin < 1 || isempty(channel)
    channel = 'mip-org/core';
end

[org, channelName] = mip.parse.parse_channel_spec(channel);

url = sprintf('https://%s.github.io/mip-%s/index.json', org, channelName);

end
