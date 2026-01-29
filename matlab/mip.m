function varargout = mip(command, varargin)
    % MIP - MATLAB Interface for mip Package Manager
    %
    % Usage:
    %   mip install <package> [...]     - Install one or more packages
    %   mip uninstall <package> [...]   - Uninstall one or more packages
    %   mip list                        - List installed packages
    %   mip load <package> [--pin]      - Load a package into MATLAB path
    %   mip unload <package>            - Unload a package from MATLAB path
    %   mip unload --all                - Unload all non-pinned packages
    %   mip pin <package>               - Pin a loaded package
    %   mip unpin <package>             - Unpin a package
    %   mip list-loaded                 - List currently loaded packages
    %   mip find-name-collisions        - Find symbol name collisions
    %   mip arch                        - Display current architecture tag
    %   mip info <package>              - Display package information
    %
    % Examples:
    %   mip install chebfun
    %   mip install package1 package2
    %   mip install https://example.com/package.mhl
    %   mip uninstall mypackage
    %   mip list
    %   mip load mypackage --pin
    %   mip unload --all
    %   mip find-name-collisions
    %   mip arch
    %   mip info chebfun
    
    if nargin < 1
        error('mip:noCommand', 'No command specified. Use "help mip" for usage information.');
    end
    
    % Normalize command to lowercase
    command = lower(command);
    
    % Handle each command
    switch command
        case 'install'
            if nargin < 2
                error('mip:noPackage', 'At least one package name required for install command.');
            end
            mip.install(varargin);
            
        case 'uninstall'
            if nargin < 2
                error('mip:noPackage', 'At least one package name required for uninstall command.');
            end
            mip.uninstall(varargin);
            
        case 'list'
            mip.list();
            
        case 'load'
            if nargin < 2
                error('mip:noPackage', 'No package specified for load command.');
            end
            packageName = varargin{1};
            mip.load(packageName, varargin{2:end});
            
        case 'unload'
            if nargin < 2
                error('mip:noPackage', 'No package specified for unload command.');
            end
            if strcmp(varargin{1}, '--all')
                mip.unload('--all');
            else
                packageName = varargin{1};
                mip.unload(packageName);
            end
            
        case 'pin'
            if nargin < 2
                error('mip:noPackage', 'No package specified for pin command.');
            end
            packageName = varargin{1};
            mip.pin(packageName);
            
        case 'unpin'
            if nargin < 2
                error('mip:noPackage', 'No package specified for unpin command.');
            end
            packageName = varargin{1};
            mip.unpin(packageName);
            
        case 'list-loaded'
            mip.list_loaded();
            
        case 'find-name-collisions'
            mip.find_name_collisions();
            
        case {'architecture', 'arch'}
            mip.arch();
            
        case 'info'
            if nargin < 2
                error('mip:noPackage', 'No package specified for info command.');
            end
            packageName = varargin{1};
            mip.info(packageName);
            
        case 'help'
            help mip;
            
        otherwise
            error('mip:unknownCommand', ...
                  'Unknown command "%s". Use "help mip" for usage information.', command);
    end
    
    % Return output if requested
    if nargout > 0
        varargout{1} = [];
    end
end
