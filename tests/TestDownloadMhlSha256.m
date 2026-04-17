classdef TestDownloadMhlSha256 < matlab.unittest.TestCase
%TESTDOWNLOADMHLSHA256   Tests for SHA-256 verification in download_mhl.

    properties
        TempDir
        SrcFile
        DestDir
    end

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.TempDir = [tempname '_dlmhl_test'];
            mkdir(testCase.TempDir);
            testCase.SrcFile = fullfile(testCase.TempDir, 'pkg.mhl');
            fid = fopen(testCase.SrcFile, 'w');
            fwrite(fid, uint8('mip test payload'));
            fclose(fid);
            testCase.DestDir = fullfile(testCase.TempDir, 'dl');
        end
    end

    methods (TestMethodTeardown)
        function teardown(testCase)
            if exist(testCase.TempDir, 'dir')
                rmdir(testCase.TempDir, 's');
            end
        end
    end

    methods (Test)

        function testMatchingDigest_Succeeds(testCase)
            % Compute the true digest via the same code path the production
            % code uses, then supply it — so the test does not depend on a
            % hardcoded hex string.
            actualSha = localSha256(testCase.SrcFile);
            testCase.assumeNotEmpty(actualSha, 'JVM unavailable — skipping');
            localPath = mip.channel.download_mhl( ...
                testCase.SrcFile, testCase.DestDir, actualSha);
            testCase.verifyTrue(exist(localPath, 'file') > 0);
        end

        function testMismatchedDigest_ErrorsAndDeletes(testCase)
            actualSha = localSha256(testCase.SrcFile);
            testCase.assumeNotEmpty(actualSha, 'JVM unavailable — skipping');
            wrongSha = repmat('0', 1, 64);
            testCase.verifyError( ...
                @() mip.channel.download_mhl( ...
                    testCase.SrcFile, testCase.DestDir, wrongSha), ...
                'mip:digestMismatch');
            expectedLocal = fullfile(testCase.DestDir, 'pkg.mhl');
            testCase.verifyFalse(exist(expectedLocal, 'file') > 0, ...
                'Local copy should be deleted on digest mismatch');
        end

        function testEmptyDigest_SkipsVerification(testCase)
            localPath = mip.channel.download_mhl( ...
                testCase.SrcFile, testCase.DestDir, '');
            testCase.verifyTrue(exist(localPath, 'file') > 0);
        end

        function testNoDigestArg_SkipsVerification(testCase)
            localPath = mip.channel.download_mhl( ...
                testCase.SrcFile, testCase.DestDir);
            testCase.verifyTrue(exist(localPath, 'file') > 0);
        end

    end
end

function hex = localSha256(filePath)
hex = '';
if ~usejava('jvm')
    return
end
try
    md = java.security.MessageDigest.getInstance('SHA-256');
    fid = fopen(filePath, 'r');
    while true
        chunk = fread(fid, 65536, '*uint8');
        if isempty(chunk)
            break
        end
        md.update(chunk);
    end
    fclose(fid);
    digest = typecast(md.digest(), 'uint8');
    hex = lower(sprintf('%02x', digest));
catch
    hex = '';
end
end
