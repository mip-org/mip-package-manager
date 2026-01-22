function archTag = get_architecture()
    % GET_ARCHITECTURE Detect the current platform architecture
    %
    % Returns:
    %   archTag - Architecture tag string (e.g., 'linux_x86_64', 'macos_arm64', 'windows_x86_64')
    %
    % This function detects the operating system and CPU architecture,
    % returning a standardized architecture tag compatible with mip package naming.
    %
    % Example:
    %   arch = mip.utils.get_architecture();
    %   % Returns: 'linux_x86_64' on Linux x64
    
    % Get platform information
    [~, maxArraySize] = computer;
    archInfo = computer('arch');
    
    % Determine OS
    if ispc
        osName = 'windows';
    elseif ismac
        osName = 'macos';
    elseif isunix
        osName = 'linux';
    else
        error('mip:unsupportedOS', 'Unsupported operating system');
    end
    
    % Determine architecture
    % MATLAB's computer('arch') returns strings like:
    % 'win64', 'glnxa64', 'maci64', 'maca64' (Apple Silicon)
    if contains(archInfo, 'arm64', 'IgnoreCase', true)
        % ARM64 architecture (Apple Silicon, ARM Linux)
        machine = 'arm64';
    elseif contains(archInfo, '64', 'IgnoreCase', true)
        % x86_64 architecture
        machine = 'x86_64';
    else
        % 32-bit or other architecture
        warning('mip:unsupportedArchitecture', ...
                'Architecture %s may not be supported by all packages', archInfo);
        machine = 'x86'; % Fallback for 32-bit systems
    end
    
    % Construct architecture tag
    archTag = sprintf('%s_%s', osName, machine);
end
