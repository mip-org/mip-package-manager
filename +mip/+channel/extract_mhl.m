function extractDir = extract_mhl(mhlPath, destDir)
%EXTRACT_MHL   Extract a .mhl package file (zip format).
%
% Args:
%   mhlPath - Path to the .mhl file
%   destDir - Destination directory for extraction
%
% Returns:
%   extractDir - Path to the extraction directory
%
% Example:
%   extractDir = mip.channel.extract_mhl('/path/to/package.mhl', '/dest/dir');

% Verify .mhl file exists
if ~exist(mhlPath, 'file')
    error('mip:mhlNotFound', '.mhl file not found: %s', mhlPath);
end

% Ensure destination directory exists
if ~exist(destDir, 'dir')
    mkdir(destDir);
end

try
    fprintf('Extracting package...\n');
    % unzip() returns a cell array of extracted file paths
    extractedFiles = unzip(mhlPath, destDir);

    if isempty(extractedFiles)
        error('mip:extractFailed', 'No files extracted from .mhl package');
    end

    % Verify no extracted files escaped destDir (path traversal check).
    % Resolve destDir to an absolute canonical path so the prefix
    % comparison is reliable even when destDir was given as a relative
    % path.  We also resolve each extracted file's parent directory
    % because unzip() may return paths containing ".." that
    % string-match the prefix yet point outside destDir.
    prevDir = cd(destDir);
    absDestDir = [pwd filesep];
    cd(prevDir);
    for i = 1:numel(extractedFiles)
        [parentDir, name, ext] = fileparts(extractedFiles{i});
        prevDir2 = cd(parentDir);
        absFile = fullfile(pwd, [name ext]);
        cd(prevDir2);
        if ~startsWith(absFile, absDestDir)
            error('mip:pathTraversal', ...
                  'Archive contains a path that escapes the destination directory: %s', ...
                  extractedFiles{i});
        end
    end

    % Verify mip.json exists in extracted files
    mipJsonPath = fullfile(destDir, 'mip.json');
    if ~exist(mipJsonPath, 'file')
        error('mip:invalidPackage', ...
              'Package is missing mip.json file. This is not a valid mip package.');
    end

    extractDir = destDir;

catch ME
    % Clean up on failure
    if exist(destDir, 'dir')
        rmdir(destDir, 's');
    end

    if strcmp(ME.identifier, 'mip:invalidPackage') || ...
       strcmp(ME.identifier, 'mip:extractFailed') || ...
       strcmp(ME.identifier, 'mip:pathTraversal')
        rethrow(ME);
    else
        error('mip:extractFailed', ...
              'Failed to extract .mhl file: %s', ME.message);
    end
end

end
