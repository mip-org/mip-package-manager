function arch = arch()
%ARCH   Get the current architecture tag.
%   ARCH() returns the architecture tag for the current system.

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

end
