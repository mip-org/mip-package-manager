classdef TestInstallMhl < matlab.unittest.TestCase
%TESTINSTALLMHL   Tests for installing packages from a local .mhl file.

    properties
        OrigMipRoot
        TestRoot
        SourceDir
        OutputDir
    end

    methods (TestMethodSetup)
        function setupTestEnvironment(testCase)
            testCase.OrigMipRoot = getenv('MIP_ROOT');
            testCase.TestRoot = [tempname '_mip_install_mhl_test'];
            mkdir(testCase.TestRoot);
            mkdir(fullfile(testCase.TestRoot, 'packages'));
            setenv('MIP_ROOT', testCase.TestRoot);

            testCase.SourceDir = [tempname '_mip_src'];
            testCase.OutputDir = [tempname '_mip_out'];
            mkdir(testCase.SourceDir);
            mkdir(testCase.OutputDir);

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
            if exist(testCase.SourceDir, 'dir')
                rmdir(testCase.SourceDir, 's');
            end
            if exist(testCase.OutputDir, 'dir')
                rmdir(testCase.OutputDir, 's');
            end
            clearMipState();
        end
    end

    methods (Test)

        function testInstallMhlAlreadyInstalled_MarksDirectlyInstalled(testCase)
            % When `mip install <pkg>.mhl` hits the early-return "already
            % installed" path, it should still mark the package as directly
            % installed. We bundle a source package, install it from the
            % .mhl, then manually remove it from directly_installed (this
            % simulates the bug scenario where the package is on disk but
            % only as a transitive dep). Re-installing from the same .mhl
            % must promote it back into directly_installed.
            srcDir = createTestSourcePackage(testCase.SourceDir, 'mypkg');
            mip.bundle(srcDir, '--output', testCase.OutputDir, '--arch', 'any');
            mhlFiles = dir(fullfile(testCase.OutputDir, '*.mhl'));
            mhlPath = fullfile(testCase.OutputDir, mhlFiles(1).name);

            mip.install(mhlPath);

            mip.state.remove_directly_installed('mip-org/core/mypkg');
            testCase.verifyFalse( ...
                ismember('gh/mip-org/core/mypkg', mip.state.get_directly_installed()));

            mip.install(mhlPath);

            testCase.verifyTrue( ...
                ismember('gh/mip-org/core/mypkg', mip.state.get_directly_installed()));
        end

    end
end
