function packages = list_installed_packages()
%LIST_INSTALLED_PACKAGES   List all installed packages as fully qualified names.
%
% Walks the on-disk packages tree and returns canonical FQNs:
%   packages/gh/<org>/<channel>/<name>  ->  gh/<org>/<channel>/<name>
%   packages/local/<name>               ->  local/<name>
%   packages/fex/<name>                 ->  fex/<name>
%
% Non-'gh' top-level entries are treated as source-type roots with a
% single level of package directories below them (variable-length FQN).
%
% Returns:
%   packages - Cell array of FQN strings, sorted.

packages = {};

packagesDir = mip.paths.get_packages_dir();
if ~exist(packagesDir, 'dir')
    return
end

topEntries = dir(packagesDir);
for i = 1:length(topEntries)
    if ~topEntries(i).isdir || startsWith(topEntries(i).name, '.')
        continue
    end
    topName = topEntries(i).name;
    topPath = fullfile(packagesDir, topName);

    if strcmp(topName, 'gh')
        % gh/<org>/<channel>/<pkg>
        orgDirs = dir(topPath);
        for j = 1:length(orgDirs)
            if ~orgDirs(j).isdir || startsWith(orgDirs(j).name, '.')
                continue
            end
            org = orgDirs(j).name;
            orgPath = fullfile(topPath, org);

            chanDirs = dir(orgPath);
            for k = 1:length(chanDirs)
                if ~chanDirs(k).isdir || startsWith(chanDirs(k).name, '.')
                    continue
                end
                ch = chanDirs(k).name;
                chanPath = fullfile(orgPath, ch);

                pkgDirs = dir(chanPath);
                for m = 1:length(pkgDirs)
                    if ~pkgDirs(m).isdir || startsWith(pkgDirs(m).name, '.')
                        continue
                    end
                    packages{end+1} = mip.parse.make_fqn(org, ch, pkgDirs(m).name); %#ok<AGROW>
                end
            end
        end
    else
        % <type>/<pkg>  (local, fex, ...)
        pkgDirs = dir(topPath);
        for j = 1:length(pkgDirs)
            if ~pkgDirs(j).isdir || startsWith(pkgDirs(j).name, '.')
                continue
            end
            packages{end+1} = [topName '/' pkgDirs(j).name]; %#ok<AGROW>
        end
    end
end

packages = sort(packages);

end
