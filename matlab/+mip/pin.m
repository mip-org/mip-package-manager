function pin(packageName)
    % pin - Pin an loaded package to prevent it from being unloaded by 'unload --all'
    %
    % Usage:
    %   mip.pin('packageName')
    %
    % This function marks a package as pinned. Pinned packages will not be
    % removed when using 'mip unload --all'.

    global MIP_LOADED_PACKAGES;
    global MIP_PINNED_PACKAGES;
    
    % Initialize if empty
    if isempty(MIP_LOADED_PACKAGES)
        MIP_LOADED_PACKAGES = {};
    end
    if isempty(MIP_PINNED_PACKAGES)
        MIP_PINNED_PACKAGES = {};
    end
    
    % Check if package is loaded
    if ~ismember(packageName, MIP_LOADED_PACKAGES)
        error('mip:packageNotLoaded', ...
              'Package "%s" is not currently loaded. Load it first with "mip load %s".', ...
              packageName, packageName);
    end
    
    % Check if already pinned
    if ismember(packageName, MIP_PINNED_PACKAGES)
        fprintf('Package "%s" is already pinned\n', packageName);
        return;
    end
    
    % Add to pinned packages
    MIP_PINNED_PACKAGES{end+1} = packageName;
    fprintf('Pinned package "%s"\n', packageName);
end
