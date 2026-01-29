function varargout = root()
%ROOT   Get the mip root directory path.
%
% Returns:
%   Path to the mip root directory (default: ~/.mip)
%
% The directory can be customized using the MIP_DIR environment variable.

% Check for MIP_DIR environment variable
mipDir = getenv('MIP_DIR');

if isempty(mipDir)
    % Default to ~/.mip
    homeDir = char(java.lang.System.getProperty('user.home'));
    mipDir  = fullfile(homeDir, '.mip');
end

if nargout == 0
    fprintf('%s\n', mipDir);
else
    varargout{1} = mipDir;
end

end
