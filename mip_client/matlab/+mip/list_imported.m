function list_imported()
    % list_imported - List all imported mip packages
    %
    % Usage:
    %   mip.list_imported()
    %
    % This function displays all currently imported packages, distinguishing
    % between packages directly imported by the user and those imported
    % as dependencies. Pinned packages are marked with a pin symbol.
    
    global MIP_IMPORTED_PACKAGES;
    global MIP_DIRECTLY_IMPORTED_PACKAGES;
    global MIP_PINNED_PACKAGES;
    
    % Initialize if empty
    if isempty(MIP_IMPORTED_PACKAGES)
        MIP_IMPORTED_PACKAGES = {};
    end
    if isempty(MIP_DIRECTLY_IMPORTED_PACKAGES)
        MIP_DIRECTLY_IMPORTED_PACKAGES = {};
    end
    if isempty(MIP_PINNED_PACKAGES)
        MIP_PINNED_PACKAGES = {};
    end
    
    % Check if any packages are imported
    if isempty(MIP_IMPORTED_PACKAGES)
        fprintf('No packages are currently imported.\n');
        return;
    end
    
    % Display directly imported packages
    fprintf('\n');
    fprintf('=== Imported Packages ===\n\n');
    
    if ~isempty(MIP_DIRECTLY_IMPORTED_PACKAGES)
        fprintf('Directly imported packages:\n');
        for i = 1:length(MIP_DIRECTLY_IMPORTED_PACKAGES)
            pkg = MIP_DIRECTLY_IMPORTED_PACKAGES{i};
            if ismember(pkg, MIP_PINNED_PACKAGES)
                fprintf('  * %s [PINNED]\n', pkg);
            else
                fprintf('  * %s\n', pkg);
            end
        end
        fprintf('\n');
    end
    
    % Find dependency packages (imported but not direct)
    dependencyPackages = {};
    for i = 1:length(MIP_IMPORTED_PACKAGES)
        pkg = MIP_IMPORTED_PACKAGES{i};
        if ~ismember(pkg, MIP_DIRECTLY_IMPORTED_PACKAGES)
            dependencyPackages{end+1} = pkg;
        end
    end
    
    % Display dependency packages
    if ~isempty(dependencyPackages)
        fprintf('Imported as dependencies:\n');
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
    fprintf('Total: %d package(s) imported (%d direct, %d dependencies, %d pinned)\n', ...
            length(MIP_IMPORTED_PACKAGES), ...
            length(MIP_DIRECTLY_IMPORTED_PACKAGES), ...
            length(dependencyPackages), ...
            numPinned);
    fprintf('\n');
end
