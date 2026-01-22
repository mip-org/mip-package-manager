function packagesDir = get_packages_dir()
    % GET_PACKAGES_DIR Get the mip packages directory path
    %
    % Returns:
    %   packagesDir - Path to the packages directory (~/.mip/packages)
    %
    % Example:
    %   packagesDir = mip.utils.get_packages_dir();
    
    mipDir = mip.utils.get_mip_dir();
    packagesDir = fullfile(mipDir, 'packages');
end
