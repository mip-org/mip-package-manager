classdef TestLoadAddpathRmpath < matlab.unittest.TestCase
%TESTLOADADDPATHRMPATH   Tests for `mip load --addpath` / `--rmpath`
% and the post-unload defensive path sweep.

    properties
        OrigMipRoot
        TestRoot
        SavedPath
    end

    methods (TestMethodSetup)
        function setupTestEnvironment(testCase)
            testCase.OrigMipRoot = getenv('MIP_ROOT');
            testCase.TestRoot = [tempname '_mip_addpath_test'];
            mkdir(testCase.TestRoot);
            mkdir(fullfile(testCase.TestRoot, 'packages'));
            setenv('MIP_ROOT', testCase.TestRoot);
            testCase.SavedPath = path;
            clearMipState();
        end
    end

    methods (TestMethodTeardown)
        function teardownTestEnvironment(testCase)
            % Restore path before any test-introduced entries vanish with
            % the temp dir (otherwise stale entries can confuse later tests).
            path(testCase.SavedPath);
            cleanupTestPaths(testCase.TestRoot);
            setenv('MIP_ROOT', testCase.OrigMipRoot);
            if exist(testCase.TestRoot, 'dir')
                rmdir(testCase.TestRoot, 's');
            end
            clearMipState();
        end
    end

    methods (Test)

        %% --- Flag parsing / validation ---

        function testAddpath_MissingValue_Errors(testCase)
            createSourcePackage(testCase, 'foo');
            testCase.verifyError(@() mip.load('foo', '--addpath'), ...
                'mip:load:missingAddpathValue');
        end

        function testRmpath_MissingValue_Errors(testCase)
            createSourcePackage(testCase, 'foo');
            testCase.verifyError(@() mip.load('foo', '--rmpath'), ...
                'mip:load:missingRmpathValue');
        end

        function testAddpath_MultiplePackages_Errors(testCase)
            createSourcePackage(testCase, 'foo');
            createSourcePackage(testCase, 'bar');
            testCase.verifyError( ...
                @() mip.load('foo', 'bar', '--addpath', 'src'), ...
                'mip:load:addpathSinglePackage');
        end

        function testRmpath_MultiplePackages_Errors(testCase)
            createSourcePackage(testCase, 'foo');
            createSourcePackage(testCase, 'bar');
            testCase.verifyError( ...
                @() mip.load('foo', 'bar', '--rmpath', 'src'), ...
                'mip:load:addpathSinglePackage');
        end

        %% --- Apply --addpath ---

        function testAddpath_AddsSourceRelativePath(testCase)
            pkgDir = createSourcePackage(testCase, 'foo', {'src/extra'});
            mip.load('foo', '--addpath', 'src/extra');
            expected = fullfile(pkgDir, 'foo', 'src', 'extra');
            testCase.verifyTrue(onPath(expected), ...
                sprintf('expected %s on path', expected));
        end

        function testAddpath_MultipleFlagsAccumulate(testCase)
            pkgDir = createSourcePackage(testCase, 'foo', {'src/a', 'src/b'});
            mip.load('foo', '--addpath', 'src/a', '--addpath', 'src/b');
            testCase.verifyTrue(onPath(fullfile(pkgDir, 'foo', 'src', 'a')));
            testCase.verifyTrue(onPath(fullfile(pkgDir, 'foo', 'src', 'b')));
        end

        function testAddpath_MissingDirWarns(testCase)
            createSourcePackage(testCase, 'foo');
            testCase.verifyWarning( ...
                @() mip.load('foo', '--addpath', 'does/not/exist'), ...
                'mip:load:addpathMissing');
        end

        function testAddpath_AppliesToAlreadyLoaded(testCase)
            pkgDir = createSourcePackage(testCase, 'foo', {'src/extra'});
            mip.load('foo');
            % Now adjust the path on the already-loaded package
            mip.load('foo', '--addpath', 'src/extra');
            testCase.verifyTrue(onPath(fullfile(pkgDir, 'foo', 'src', 'extra')));
        end

        %% --- Apply --rmpath ---

        function testRmpath_RemovesPreLoadedPath(testCase)
            % load_package.m adds pkg_dir; --rmpath foo (the source subdir)
            % removes the source subdir if it was on the path.
            pkgDir = createSourcePackage(testCase, 'foo');
            sourceSubdir = fullfile(pkgDir, 'foo');
            addpath(sourceSubdir);
            testCase.verifyTrue(onPath(sourceSubdir));
            mip.load('foo', '--rmpath', '.');
            testCase.verifyFalse(onPath(sourceSubdir), ...
                '--rmpath should remove the source-relative target');
        end

        %% --- Unload sweep ---

        function testUnload_SweepsAddpathEntries(testCase)
            pkgDir = createSourcePackage(testCase, 'foo', {'src/extra'});
            mip.load('foo', '--addpath', 'src/extra');
            target = fullfile(pkgDir, 'foo', 'src', 'extra');
            testCase.verifyTrue(onPath(target));

            mip.unload('foo');
            testCase.verifyFalse(onPath(target), ...
                'unload sweep should remove --addpath entries');
        end

        function testUnload_SweepsLoadPackageEntriesIfMissingUnloadScript(testCase)
            % Build a package where load_package.m adds a path but
            % unload_package.m DOES NOT remove it. The sweep should still
            % clean it up.
            pkgDir = createSourcePackage(testCase, 'foo');
            sourceSubdir = fullfile(pkgDir, 'foo');
            % Replace unload_package.m with a no-op
            fid = fopen(fullfile(pkgDir, 'unload_package.m'), 'w');
            fprintf(fid, 'function unload_package()\nend\n');
            fclose(fid);

            mip.load('foo');
            testCase.verifyTrue(onPath(sourceSubdir), ...
                'load_package.m should have added the source subdir');

            mip.unload('foo');
            testCase.verifyFalse(onPath(sourceSubdir), ...
                'sweep should remove the residual entry');
        end

        function testUnload_DoesNotTouchUnrelatedSiblingPaths(testCase)
            % Create a sibling directory whose name shares a prefix with
            % the package source dir. The sweep must not touch it.
            pkgDir = createSourcePackage(testCase, 'foo');
            sourceSubdir = fullfile(pkgDir, 'foo');
            siblingDir = [sourceSubdir '_sibling'];
            mkdir(siblingDir);
            addpath(siblingDir);

            mip.load('foo');
            mip.unload('foo');

            testCase.verifyTrue(onPath(siblingDir), ...
                'sweep must not remove sibling path with shared prefix');
        end

        %% --- --addpath does NOT propagate to dependencies ---

        function testAddpath_NotAppliedToDependencies(testCase)
            % Dep `dep1` has a src/extra dir. Main package depends on dep1.
            % Loading the main package with --addpath src/extra should
            % NOT addpath the dep's src/extra.
            depDir = createSourcePackage(testCase, 'dep1', {'src/extra'});
            mainDir = createSourcePackage(testCase, 'main', ...
                {'src/extra'}, {'dep1'});

            mip.load('main', '--addpath', 'src/extra');

            mainTarget = fullfile(mainDir, 'main', 'src', 'extra');
            depTarget = fullfile(depDir, 'dep1', 'src', 'extra');
            testCase.verifyTrue(onPath(mainTarget), ...
                '--addpath should apply to the named package');
            testCase.verifyFalse(onPath(depTarget), ...
                '--addpath must not propagate to dependencies');
        end

    end
end


function pkgDir = createSourcePackage(testCase, pkgName, subdirs, deps)
% Create a non-editable installed package shaped like the standard mip
% layout: pkgDir/load_package.m, unload_package.m, mip.json, and a
% pkgDir/<pkgName>/ subdir containing the source. load_package.m adds
% pkgDir/<pkgName>/ to the path; unload_package.m removes it.
%
% subdirs (optional): cell array of source-relative subdirs to mkdir
%                     under pkgDir/<pkgName>/.
% deps    (optional): cell array of dependency names to record in mip.json.

    if nargin < 3, subdirs = {}; end
    if nargin < 4, deps = {}; end

    pkgDir = fullfile(testCase.TestRoot, 'packages', 'mip-org', 'core', pkgName);
    if ~exist(pkgDir, 'dir')
        mkdir(pkgDir);
    end
    sourceDir = fullfile(pkgDir, pkgName);
    mkdir(sourceDir);
    for i = 1:numel(subdirs)
        mkdir(fullfile(sourceDir, subdirs{i}));
    end

    % mip.json
    mipData = struct( ...
        'name', pkgName, ...
        'version', '1.0.0', ...
        'description', '', ...
        'architecture', 'any');
    if isempty(deps)
        mipData.dependencies = reshape({}, 0, 1);
    else
        mipData.dependencies = deps;
    end
    fid = fopen(fullfile(pkgDir, 'mip.json'), 'w');
    fwrite(fid, jsonencode(mipData));
    fclose(fid);

    % load_package.m: addpath(pkg_dir/<pkgName>)
    fid = fopen(fullfile(pkgDir, 'load_package.m'), 'w');
    fprintf(fid, 'function load_package()\n');
    fprintf(fid, '    pkg_dir = fileparts(mfilename(''fullpath''));\n');
    fprintf(fid, '    addpath(fullfile(pkg_dir, ''%s''));\n', pkgName);
    fprintf(fid, 'end\n');
    fclose(fid);

    % unload_package.m: rmpath(pkg_dir/<pkgName>)
    fid = fopen(fullfile(pkgDir, 'unload_package.m'), 'w');
    fprintf(fid, 'function unload_package()\n');
    fprintf(fid, '    pkg_dir = fileparts(mfilename(''fullpath''));\n');
    fprintf(fid, '    target = fullfile(pkg_dir, ''%s'');\n', pkgName);
    fprintf(fid, '    if ismember(target, strsplit(path, pathsep))\n');
    fprintf(fid, '        rmpath(target);\n');
    fprintf(fid, '    end\n');
    fprintf(fid, 'end\n');
    fclose(fid);
end


function tf = onPath(p)
    tf = ismember(p, strsplit(path, pathsep));
end
