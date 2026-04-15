classdef TestInstallZipUrl < matlab.unittest.TestCase
%TESTINSTALLZIPURL   Tests for `mip install <zip-url> --name <name>`.
% Validation tests do not require network. The end-to-end download path
% is covered by manual smoke testing; these tests focus on argument
% categorization, flag validation, and download-error surfacing.

    properties
        OrigMipRoot
        TestRoot
    end

    methods (TestMethodSetup)
        function setupTestEnvironment(testCase)
            testCase.OrigMipRoot = getenv('MIP_ROOT');
            testCase.TestRoot = [tempname '_mip_zip_test'];
            mkdir(testCase.TestRoot);
            mkdir(fullfile(testCase.TestRoot, 'packages'));
            setenv('MIP_ROOT', testCase.TestRoot);
            clearMipState();
        end
    end

    methods (TestMethodTeardown)
        function teardownTestEnvironment(testCase)
            cleanupTestPaths(testCase.TestRoot);
            setenv('MIP_ROOT', testCase.OrigMipRoot);
            if exist(testCase.TestRoot, 'dir')
                rmdir(testCase.TestRoot, 's');
            end
            clearMipState();
        end
    end

    methods (Test)

        %% --- Validation: --name flag scoping ---

        function testZipUrl_RequiresName(testCase)
            testCase.verifyError( ...
                @() mip.install('https://example.com/foo.zip'), ...
                'mip:install:nameRequiredForZipUrl');
        end

        function testNameWithoutZipUrl_Errors(testCase)
            testCase.verifyError( ...
                @() mip.install('chebfun', '--name', 'whatever'), ...
                'mip:install:nameRequiresZipUrl');
        end

        function testNameWithLocalPath_Errors(testCase)
            % --name is only valid when at least one .zip URL is present.
            testCase.verifyError( ...
                @() mip.install('./somepkg', '--name', 'whatever'), ...
                'mip:install:nameRequiresZipUrl');
        end

        function testMultipleZipUrls_Error(testCase)
            testCase.verifyError( ...
                @() mip.install('https://a.com/x.zip', 'https://b.com/y.zip', ...
                                '--name', 'foo'), ...
                'mip:install:multipleZipUrls');
        end

        function testNameMissingValue_Errors(testCase)
            testCase.verifyError( ...
                @() mip.install('https://example.com/foo.zip', '--name'), ...
                'mip:install:missingNameValue');
        end

        function testEditableWithZipUrl_Errors(testCase)
            testCase.verifyError( ...
                @() mip.install('-e', 'https://example.com/foo.zip', ...
                                '--name', 'foo'), ...
                'mip:install:editableRequiresLocal');
        end

        %% --- URL detection ---

        function testMhlUrlNotClassifiedAsZip(testCase)
            % A .mhl URL is NOT a zip URL: passing --name with it should
            % fire nameRequiresZipUrl (which only triggers when no zip
            % URL is in the args).
            testCase.verifyError( ...
                @() mip.install('https://example.com/foo.mhl', '--name', 'x'), ...
                'mip:install:nameRequiresZipUrl');
        end

        function testZipUrlDetection_QueryString(testCase)
            % URL with .zip in path and a query string is still a zip URL.
            testCase.verifyError( ...
                @() mip.install('https://example.com/foo.zip?token=abc'), ...
                'mip:install:nameRequiredForZipUrl');
        end

        function testZipUrlDetection_GitHubArchive(testCase)
            testCase.verifyError( ...
                @() mip.install('https://github.com/foo/bar/archive/refs/heads/main.zip'), ...
                'mip:install:nameRequiredForZipUrl');
        end

        function testZipUrlDetection_UppercaseExtension(testCase)
            testCase.verifyError( ...
                @() mip.install('https://example.com/Foo.ZIP'), ...
                'mip:install:nameRequiredForZipUrl');
        end

        function testZipInQueryStringOnly_NotZipUrl(testCase)
            % .zip only in the query string (not the path) is NOT a zip URL.
            % With --name, this fires nameRequiresZipUrl since no zip URL
            % was detected.
            testCase.verifyError( ...
                @() mip.install('https://example.com/foo?file=bar.zip', ...
                                '--name', 'whatever'), ...
                'mip:install:nameRequiresZipUrl');
        end

        %% --- Download failure surfacing ---

        function testZipUrl_DownloadFailure(testCase)
            % Unreachable URL: websave errors and we surface
            % mip:install:zipDownloadFailed.
            testCase.verifyError( ...
                @() mip.install('https://127.0.0.1:1/nonexistent.zip', ...
                                '--name', 'nope'), ...
                'mip:install:zipDownloadFailed');
        end

    end
end
