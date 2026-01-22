function varargout = mip(command, varargin)
    % mip - MATLAB Interface for mip Package Manager
    %
    % Usage:
    %   mip load <package> [--pin]  - Load a package (optionally pin it)
    %   mip unload <package>        - Unload a package
    %   mip unload --all            - Unload all non-pinned packages
    %   mip pin <package>           - Pin a loaded package
    %   mip unpin <package>         - Unpin a package
    %   mip install <package>       - Install a package
    %   mip uninstall <package>     - Uninstall a package
    %   mip list-loaded             - List currently loaded packages
    %   mip list                    - List installed packages
    %   mip setup                   - Set up MATLAB integration
    %   mip find-name-collisions    - Find symbol name collisions
    %
    % Examples:
    %   mip load mypackage
    %   mip load mypackage --pin
    %   mip pin mypackage
    %   mip unload --all
    %   mip install mypackage
    %   mip uninstall mypackage
    %   mip list
    
    if nargin < 1
        error('mip:noCommand', 'No command specified. Use "mip help" for usage information.');
    end

    % Handle 'load' command by calling mip.load
    if strcmp(command, 'load')
        if nargin < 2
            error('mip:noPackage', 'No package specified for load command.');
        end
        packageName = varargin{1};
        % Call mip.load with the package name and any additional arguments
        mip.load(packageName, varargin{2:end});
        return;
    end

    % Handle 'unload' command by calling mip.unload
    if strcmp(command, 'unload')
        if nargin < 2
            error('mip:noPackage', 'No package specified for unload command.');
        end
        % Check for --all flag
        if strcmp(varargin{1}, '--all')
            mip.unload('--all');
        else
            packageName = varargin{1};
            % Call mip.unload with the package name
            mip.unload(packageName);
        end
        return;
    end

    % Handle 'pin' command by calling mip.pin
    if strcmp(command, 'pin')
        if nargin < 2
            error('mip:noPackage', 'No package specified for pin command.');
        end
        packageName = varargin{1};
        mip.pin(packageName);
        return;
    end

    % Handle 'unpin' command by calling mip.unpin
    if strcmp(command, 'unpin')
        if nargin < 2
            error('mip:noPackage', 'No package specified for unpin command.');
        end
        packageName = varargin{1};
        mip.unpin(packageName);
        return;
    end

    % Handle 'list-loaded' command by calling mip.list_loaded
    if strcmp(command, 'list-loaded')
        mip.list_loaded();
        return;
    end

    % For all other commands, forward to system call
    % Build the command string
    cmdStr = 'mip';
    cmdStr = [cmdStr, ' ', command];
    
    % Add all additional arguments
    for i = 1:length(varargin)
        arg = varargin{i};
        if ischar(arg) || isstring(arg)
            % Add quotes if argument contains spaces
            if contains(arg, ' ')
                cmdStr = [cmdStr, ' "', char(arg), '"'];
            else
                cmdStr = [cmdStr, ' ', char(arg)];
            end
        else
            error('mip:invalidArgument', 'All arguments must be strings or chars.');
        end
    end
    
    % Execute the system command
    [status, output] = system(cmdStr);
    
    % Display the output
    if ~isempty(output)
        fprintf('%s', output);
    end
    
    % Check for errors
    if status ~= 0
        error('mip:commandFailed', 'Command failed with status %d', status);
    end
    
    % Return output if requested
    if nargout > 0
        varargout{1} = output;
    end
end
