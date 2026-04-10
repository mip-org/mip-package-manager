function tf = check_needs_update(installedInfo, latestInfo)
%CHECK_NEEDS_UPDATE   Compare installed vs latest version and commit hash.
%
% Returns true if the latest version differs from installed, or if the
% versions match but the commit hash has changed.

    installedVersion = installedInfo.version;
    latestVersion = latestInfo.version;

    if ~strcmp(installedVersion, latestVersion)
        tf = true;
        return
    end

    installedHash = '';
    if isfield(installedInfo, 'commit_hash')
        installedHash = installedInfo.commit_hash;
    end
    latestHash = '';
    if isfield(latestInfo, 'commit_hash')
        latestHash = latestInfo.commit_hash;
    end

    tf = ~isempty(latestHash) && ~strcmp(installedHash, latestHash);
end
