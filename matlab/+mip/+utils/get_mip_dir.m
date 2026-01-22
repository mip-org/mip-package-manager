function mipDir = get_mip_dir()
    % GET_MIP_DIR Get the mip root directory path
    %
    % Returns:
    %   mipDir - Path to the mip directory (default: ~/.mip)
    %
    % The directory can be customized using the MIP_DIR environment variable.
    %
    % Example:
    %   mipDir = mip.utils.get_mip_dir();
    
    % Check for MIP_DIR environment variable
    mipDirEnv = getenv('MIP_DIR');
    
    if ~isempty(mipDirEnv)
        mipDir = mipDirEnv;
    else
        % Default to ~/.mip
        if ispc
            % Windows
            homeDir = getenv('USERPROFILE');
        else
            % Unix-like (Linux, macOS)
            homeDir = getenv('HOME');
        end
        
        if isempty(homeDir)
            error('mip:homeDirNotFound', ...
                  'Could not determine home directory. Please set MIP_DIR environment variable.');
        end
        
        mipDir = fullfile(homeDir, '.mip');
    end
end
