function varargout = mip(command, varargin)
%MIP   A package manager for MATLAB/MEX.
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
%   mip index                       - Display the mip package index URL.
%   mip help [command]              - Show help text for command

if nargin < 1
    command = 'help';
end

% Normalize command to lowercase
command = lower(command);

% Handle each command
switch command
    case 'install'
        if nargin < 2
            error('mip:noPackage', 'At least one package name required for install command.');
        end
        mip.install(varargin{:});

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
        fprintf('%s\n', mip.arch());

    case 'info'
        if nargin < 2
            error('mip:noPackage', 'No package specified for info command.');
        end
        packageName = varargin{1};
        mip.info(packageName);

    case 'index'
        fprintf('%s\n', mip.index());

    case 'root'
        fprintf('%s\n', mip.root());

    case 'help'
        if nargin > 1
            % Show help text for command
            command = ['+mip/' strrep(varargin{1}, '-', '_') '.m'];
            if ~exist(command, 'file')
                error('mip:unknownCommand', ['Unknown mip command ''' varargin{1} '''.']);
            end
            help(command);
        else
            help mip;
        end

    otherwise
        error('mip:unknownCommand', ...
              'Unknown command "%s". Use "help mip" for usage information.', command);
end

% Return output if requested
if nargout > 0
    varargout{1} = [];
end

end
