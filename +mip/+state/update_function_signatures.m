function update_function_signatures(targetResourcesDir)
%UPDATE_FUNCTION_SIGNATURES   Regenerate MATLAB tab-completion metadata.
%
% Writes <mip>/resources/functionSignatures.json describing the current
% subcommands and package-name choices for the 'mip' command, so the
% MATLAB editor and Command Window can offer tab completion.
%
% Called after any mip subcommand that changes installed, loaded, or
% pinned state.
%
% Usage:
%   mip.state.update_function_signatures()
%   mip.state.update_function_signatures(targetResourcesDir)
%
% The optional targetResourcesDir override is provided for tests so they
% do not clobber the real signature file in the installed mip directory.

    if nargin < 1 || isempty(targetResourcesDir)
        % Default target: the 'resources' folder alongside mip.m.
        % This file lives at <mip>/+mip/+state/update_function_signatures.m
        stateDir = fileparts(mfilename('fullpath'));  % .../+mip/+state
        mipNsDir = fileparts(stateDir);               % .../+mip
        mipDir   = fileparts(mipNsDir);               % .../mip (contains mip.m)
        targetResourcesDir = fullfile(mipDir, 'resources');
    end

    if ~exist(targetResourcesDir, 'dir')
        [ok, ~, ~] = mkdir(targetResourcesDir);
        if ~ok
            return
        end
    end

    installed = bare_names(mip.state.list_installed_packages());
    loaded    = bare_names(mip.state.key_value_get('MIP_LOADED_PACKAGES'));
    pinned    = bare_names(mip.state.get_pinned());

    json = build_signatures(installed, loaded, pinned);

    jsonPath = fullfile(targetResourcesDir, 'functionSignatures.json');
    fid = fopen(jsonPath, 'w');
    if fid == -1
        return
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, json);
end


function names = bare_names(fqns)
    if isempty(fqns)
        names = {};
        return
    end
    n = numel(fqns);
    names = cell(1, n);
    for i = 1:n
        parts = strsplit(fqns{i}, '/');
        names{i} = parts{end};
    end
    names = unique(names);
end


function json = build_signatures(installed, loaded, pinned)
% Emit a JSON object with one "mip" signature per subcommand. MATLAB's
% function-signature format explicitly supports duplicate top-level keys
% for functions with multiple syntaxes.

    subcommands = {'install','update','uninstall','list','load','unload', ...
                   'pin','unpin','info','test','compile','bundle','init', ...
                   'reset','avail','index','arch','root','version','help'};

    lines = {'{', '  "_schemaVersion": "1.0.0"'};
    for i = 1:numel(subcommands)
        cmd = subcommands{i};
        sig = signature_for(cmd, installed, loaded, pinned, subcommands);
        lines{end+1} = ','; %#ok<AGROW>
        lines{end+1} = sprintf('  "mip": %s', sig); %#ok<AGROW>
    end
    lines{end+1} = '}';
    json = [strjoin(lines, newline) newline];
end


function sig = signature_for(cmd, installed, loaded, pinned, subcommands)
    inputs = { command_arg(cmd) };

    switch cmd
        case {'load','uninstall','pin','update','compile','test','info'}
            inputs{end+1} = pkg_arg(installed);
        case 'unload'
            inputs{end+1} = pkg_arg(loaded);
        case 'unpin'
            inputs{end+1} = pkg_arg(pinned);
        case 'help'
            inputs{end+1} = choices_arg('subcommand', 'ordered', subcommands);
        case 'install'
            inputs{end+1} = '{"name":"package","kind":"required","repeating":true,"type":["char"]}';
        case 'bundle'
            inputs{end+1} = '{"name":"directory","kind":"required","type":["folder"]}';
        case 'init'
            inputs{end+1} = '{"name":"directory","kind":"ordered","type":["folder"]}';
    end

    sig = sprintf('{"inputs":[%s]}', strjoin(inputs, ','));
end


function arg = command_arg(cmd)
    arg = sprintf('{"name":"command","kind":"required","type":["char","choices={%s}"]}', quote_one(cmd));
end


function arg = pkg_arg(names)
    arg = choices_arg('package', 'required_repeating', names);
end


function arg = choices_arg(name, kind, names)
    switch kind
        case 'required_repeating'
            head = sprintf('"name":"%s","kind":"required","repeating":true', name);
        case 'ordered'
            head = sprintf('"name":"%s","kind":"ordered"', name);
        otherwise
            head = sprintf('"name":"%s","kind":"required"', name);
    end
    if isempty(names)
        arg = sprintf('{%s,"type":["char"]}', head);
    else
        quoted = cellfun(@quote_one, names, 'UniformOutput', false);
        arg = sprintf('{%s,"type":["char","choices={%s}"]}', head, strjoin(quoted, ','));
    end
end


function q = quote_one(s)
% MATLAB-quote a string for a choices={...} expression (single quotes,
% doubled to escape any embedded single quote).
    q = ['''' strrep(s, '''', '''''') ''''];
end
