function list_loaded()
    % list_loaded - List all loaded mip packages
    %
    % Usage:
    %   mip.list_loaded()
    %
    % This function displays all currently loaded packages, distinguishing
    % between packages directly loaded by the user and those loaded
    % as dependencies. Pinned packages are marked with a pin symbol.
    
    global MIP_LOADED_PACKAGES;
    global MIP_DIRECTLY_LOADED_PACKAGES;
    global MIP_PINNED_PACKAGES;
    
    % Initialize if empty
    if isempty(MIP_LOADED_PACKAGES)
        MIP_LOADED_PACKAGES = {};
    end
    if isempty(MIP_DIRECTLY_LOADED_PACKAGES)
        MIP_DIRECTLY_LOADED_PACKAGES = {};
    end
    if isempty(MIP_PINNED_PACKAGES)
        MIP_PINNED_PACKAGES = {};
    end
    
    % Check if any packages are loaded
    if isempty(MIP_LOADED_PACKAGES)
        fprintf('No packages are currently loaded.\n');
        return;
    end
    
    % Display directly loaded packages
    fprintf('\n');
    fprintf('=== Loaded Packages ===\n\n');

    if ~isempty(MIP_DIRECTLY_LOADED_PACKAGES)
        fprintf('Directly loaded packages:\n');
        for i = 1:length(MIP_DIRECTLY_LOADED_PACKAGES)
            pkg = MIP_DIRECTLY_LOADED_PACKAGES{i};
            if ismember(pkg, MIP_PINNED_PACKAGES)
                fprintf('  * %s [PINNED]\n', pkg);
            else
                fprintf('  * %s\n', pkg);
            end
        end
        fprintf('\n');
    end

    % Find dependency packages (loaded but not direct)
    dependencyPackages = {};
    for i = 1:length(MIP_LOADED_PACKAGES)
        pkg = MIP_LOADED_PACKAGES{i};
        if ~ismember(pkg, MIP_DIRECTLY_LOADED_PACKAGES)
            dependencyPackages{end+1} = pkg;
        end
    end
    
    % Display dependency packages
    if ~isempty(dependencyPackages)
        fprintf('Loaded as dependencies:\n');
        for i = 1:length(dependencyPackages)
            pkg = dependencyPackages{i};
            if ismember(pkg, MIP_PINNED_PACKAGES)
                fprintf('  - %s [PINNED]\n', pkg);
            else
                fprintf('  - %s\n', pkg);
            end
        end
        fprintf('\n');
    end
    
    % Summary
    numPinned = length(MIP_PINNED_PACKAGES);
    fprintf('Total: %d package(s) loaded (%d direct, %d dependencies, %d pinned)\n', ...
            length(MIP_LOADED_PACKAGES), ...
            length(MIP_DIRECTLY_LOADED_PACKAGES), ...
            length(dependencyPackages), ...
            numPinned);
    fprintf('\n');
end
