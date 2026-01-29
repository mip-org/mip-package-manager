function varargout = arch()
%ARCH   Display the current architecture tag.
%
% Usage:
%   mip.arch()
%
% Displays the architecture tag for the current system, which is used
% to determine package compatibility.
%
% Example:
%   mip.arch()
%   % Output: linux_x86_64

switch computer('arch')
    case 'glnxa64'
        arch = 'linux_x86_64';
    case 'maca64'
        arch = 'macos_arm64';
    case 'maci64'
        arch = 'macos_x86_64';
    case 'win64'
        arch = 'windows_x86_64';
end

if nargout == 0
    fprintf('%s\n', arch);
else
    varargout{1} = arch;
end

end
