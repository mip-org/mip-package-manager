function unpin(packageName)
    % unpin - Unpin a package to allow it to be unloaded by 'unload --all'
    %
    % Usage:
    %   mip.unpin('packageName')
    %
    % This function removes the pin from a package, allowing it to be
    % unloaded with 'mip unload --all'.

    global MIP_PINNED_PACKAGES;
    
    % Initialize if empty
    if isempty(MIP_PINNED_PACKAGES)
        MIP_PINNED_PACKAGES = {};
    end
    
    % Check if package is pinned
    if ~ismember(packageName, MIP_PINNED_PACKAGES)
        fprintf('Package "%s" is not currently pinned\n', packageName);
        return;
    end
    
    % Remove from pinned packages
    MIP_PINNED_PACKAGES = MIP_PINNED_PACKAGES(...
        ~strcmp(MIP_PINNED_PACKAGES, packageName));
    
    fprintf('Unpinned package "%s"\n', packageName);
