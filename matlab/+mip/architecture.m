function architecture()
    % ARCHITECTURE Display the current architecture tag
    %
    % Usage:
    %   mip.architecture()
    %
    % Displays the architecture tag for the current system, which is used
    % to determine package compatibility.
    %
    % Example:
    %   mip.architecture()
    %   % Output: linux_x86_64
    
    archTag = mip.utils.get_architecture();
    fprintf('%s\n', archTag);
end
