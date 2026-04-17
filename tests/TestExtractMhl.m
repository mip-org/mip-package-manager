classdef TestExtractMhl < matlab.unittest.TestCase
%TESTEXTRACTMHL   Tests for mip.channel.extract_mhl path traversal guard.

    properties
        TempDir
    end

    methods (TestMethodSetup)
        function setupTempDir(testCase)
            testCase.TempDir = [tempname '_mhl_test'];
            mkdir(testCase.TempDir);
        end
    end

    methods (TestMethodTeardown)
        function teardownTempDir(testCase)
            if exist(testCase.TempDir, 'dir')
                rmdir(testCase.TempDir, 's');
            end
        end
    end

    methods (Test)

        function testValidMhl_ExtractsSuccessfully(testCase)
            mhlPath = createValidMhl(testCase.TempDir);
            destDir = fullfile(testCase.TempDir, 'out');
            result = mip.channel.extract_mhl(mhlPath, destDir);
            testCase.verifyTrue(exist(fullfile(result, 'mip.json'), 'file') > 0);
        end

        function testPathTraversal_Rejected(testCase)
            mhlPath = createTraversalMhl(testCase.TempDir);
            destDir = fullfile(testCase.TempDir, 'out');
            testCase.verifyError( ...
                @() mip.channel.extract_mhl(mhlPath, destDir), ...
                'mip:pathTraversal');
            % destDir should be cleaned up on error
            testCase.verifyFalse(exist(destDir, 'dir') > 0, ...
                'destDir should be removed after path traversal error');
        end

        function testMissingMipJson_Rejected(testCase)
            mhlPath = createNoJsonMhl(testCase.TempDir);
            destDir = fullfile(testCase.TempDir, 'out');
            testCase.verifyError( ...
                @() mip.channel.extract_mhl(mhlPath, destDir), ...
                'mip:invalidPackage');
        end

    end
end

%% Helpers

function mhlPath = createValidMhl(baseDir)
    mhlPath = fullfile(baseDir, 'valid.mhl');
    pyScript = sprintf([ ...
        'import zipfile, json\n' ...
        'with zipfile.ZipFile(r"%s", "w") as zf:\n' ...
        '    zf.writestr("mip.json", json.dumps({"name":"testpkg","version":"1.0.0"}))\n' ...
        '    zf.writestr("hello.m", "function hello(); end")\n'], mhlPath);
    [status, output] = system(sprintf('python3 -c "%s"', strrep(pyScript, '"', '\"')));
    assert(status == 0, 'Failed to create valid mhl: %s', output);
end

function mhlPath = createTraversalMhl(baseDir)
    mhlPath = fullfile(baseDir, 'traversal.mhl');
    pyScript = sprintf([ ...
        'import zipfile, json\n' ...
        'with zipfile.ZipFile(r"%s", "w") as zf:\n' ...
        '    zf.writestr("mip.json", json.dumps({"name":"testpkg","version":"1.0.0"}))\n' ...
        '    zf.writestr("../escaped.txt", "pwned")\n'], mhlPath);
    [status, output] = system(sprintf('python3 -c "%s"', strrep(pyScript, '"', '\"')));
    assert(status == 0, 'Failed to create traversal mhl: %s', output);
end

function mhlPath = createNoJsonMhl(baseDir)
    mhlPath = fullfile(baseDir, 'nojson.mhl');
    pyScript = sprintf([ ...
        'import zipfile\n' ...
        'with zipfile.ZipFile(r"%s", "w") as zf:\n' ...
        '    zf.writestr("hello.m", "function hello(); end")\n'], mhlPath);
    [status, output] = system(sprintf('python3 -c "%s"', strrep(pyScript, '"', '\"')));
    assert(status == 0, 'Failed to create no-json mhl: %s', output);
end
