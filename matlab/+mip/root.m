function root = root()
%ROOT   Get the mip root directory path.
%   ROOT() returns the path to the mip root directory (default: ~/.mip). The mip
%   directory can be customized by setting the MIP_DIR environment variable.

% Check for MIP_DIR environment variable
root = getenv('MIP_DIR');

if isempty(root)
    % Default to ~/.mip
    home = char(java.lang.System.getProperty('user.home'));
    root  = fullfile(home, '.mip');
end

end
