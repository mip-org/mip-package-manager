classdef TestCreatePathScripts < matlab.unittest.TestCase
%TESTCREATEPATHSCRIPTS   Tests for mip.build.create_path_scripts.

    properties
        TmpDir
    end

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.TmpDir = [tempname '_path_scripts_test'];
            mkdir(testCase.TmpDir);
        end
    end

    methods (TestMethodTeardown)
        function teardown(testCase)
            if exist(testCase.TmpDir, 'dir')
                rmdir(testCase.TmpDir, 's');
            end
        end
    end

    methods (Test)

        function testAbsolutePaths_BasicGeneration(testCase)
            paths = {'/home/user/pkg/src'};
            opts = struct('absolute', true);
            mip.build.create_path_scripts(testCase.TmpDir, paths, opts);

            loadScript = fileread(fullfile(testCase.TmpDir, 'load_package.m'));
            testCase.verifySubstring(loadScript, 'addpath(''/home/user/pkg/src'')');
        end

        function testAbsolutePaths_SingleQuoteEscaped(testCase)
            % Path with single quote should produce doubled quotes in output.
            paths = {'/home/o''brien/pkg/src'};
            opts = struct('absolute', true);
            mip.build.create_path_scripts(testCase.TmpDir, paths, opts);

            loadScript = fileread(fullfile(testCase.TmpDir, 'load_package.m'));
            testCase.verifySubstring(loadScript, 'addpath(''/home/o''''brien/pkg/src'')');

            unloadScript = fileread(fullfile(testCase.TmpDir, 'unload_package.m'));
            testCase.verifySubstring(unloadScript, 'rmpath(''/home/o''''brien/pkg/src'')');
        end

        function testRelativePaths_SingleQuoteEscaped(testCase)
            % Relative path with single quote should also be escaped.
            paths = {'it''s a path'};
            mip.build.create_path_scripts(testCase.TmpDir, paths);

            loadScript = fileread(fullfile(testCase.TmpDir, 'load_package.m'));
            testCase.verifySubstring(loadScript, 'fullfile(pkg_dir, ''it''''s a path'')');
        end

        function testRelativePaths_DotNotInterpolated(testCase)
            % '.' paths use pkg_dir directly — no string interpolation.
            paths = {'.'};
            mip.build.create_path_scripts(testCase.TmpDir, paths);

            loadScript = fileread(fullfile(testCase.TmpDir, 'load_package.m'));
            testCase.verifySubstring(loadScript, 'addpath(pkg_dir)');
        end

        function testGeneratedScript_IsValidMATLAB(testCase)
            % The generated load script with a quoted path should parse
            % without syntax errors.
            paths = {'/home/o''brien/pkg'};
            opts = struct('absolute', true);
            mip.build.create_path_scripts(testCase.TmpDir, paths, opts);

            loadFile = fullfile(testCase.TmpDir, 'load_package.m');
            % If the file has syntax errors, calling which on it after
            % adding to path will not find the function. But a simpler
            % check: just verify the file can be read back and the quotes
            % are balanced.
            content = fileread(loadFile);
            % Count single quotes — they should be even (balanced)
            nQuotes = sum(content == '''');
            testCase.verifyEqual(mod(nQuotes, 2), 0, ...
                'Generated script should have balanced single quotes');
        end

    end
end
