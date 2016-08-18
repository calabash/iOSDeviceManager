using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Text;
using Semver;

namespace DeviceAgent.iOS.Dependencies
{

    public static class DeploymentManager
    {
        const string VersionFileName = "version.txt";

        const string VersionResource = "DeviceAgent.iOS.Dependencies.version.txt";
        const string DependenciesResource = "DeviceAgent.iOS.Dependencies.dependencies.zip";
        
        static Lazy<SemVersion> _version = new Lazy<SemVersion>(() => {
            using (var versionStream = MyAssembly.GetManifestResourceStream(VersionResource))
            {
                using (var reader = new StreamReader(versionStream, Encoding.UTF8))
                {
                    return SemVersion.Parse(reader.ReadToEnd());
                }
            }
        });

        static Assembly MyAssembly => typeof(DeploymentManager).GetTypeInfo().Assembly;

        public static SemVersion DeviceAgentVersion =>  _version.Value;

        public static string PathToiOSDeviceManager { get; } = Path.Combine("bin", "iOSDeviceManager");

        public static string PathToDeviceTestRunner { get; } = Path.Combine("ipa", "CBX-Runner.app");

        public static string PathToSimTestRunner { get; } = Path.Combine("app", "CBX-Runner.app");

        public static string PathToDeviceTestBundle { get; } = Path.Combine(PathToDeviceTestRunner, "PlugIns", "CBX.xctest");

        public static string PathToSimTestBundle { get; } = Path.Combine(PathToSimTestRunner, "PlugIns", "CBX.xctest");

        public static void InstallOrUpdateIfNecessary(string directory)
        {
            if (IsUpToDate(directory))
            {
                return;
            }

            if (Directory.Exists(directory))
            {
                Directory.Delete(directory, true);
            }

            Directory.CreateDirectory(directory);

            var tempZipPath = Path.Combine(directory, "dependencies.zip");

            using (var versionStream = MyAssembly.GetManifestResourceStream(DependenciesResource))
            {
                using (var tempZip = File.Create(tempZipPath))
                {
                    versionStream.CopyTo(tempZip);
                }
            }

            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = "/usr/bin/unzip",
                    Arguments = $"-q {tempZipPath} -d {directory}", 
                    UseShellExecute = false,
                    CreateNoWindow = true
                }
            };

            process.Start();

            process.WaitForExit();

            if (process.ExitCode != 0)
            {
                throw new IOException(
                    $"Unpacking dependencies failed: {process.StartInfo.FileName} {process.StartInfo.Arguments}");
            }

            File.Delete(tempZipPath);

            File.WriteAllText(Path.Combine(directory, VersionFileName), DeviceAgentVersion.ToString());
        }

        static bool IsUpToDate(string directory)
        {
            var versionFile = Path.Combine(directory, VersionFileName);

            if (File.Exists(versionFile))
            {
                using (var textReader = File.OpenText(versionFile))
                {
                    var currentVersion = SemVersion.Parse(textReader.ReadToEnd());

                    if (currentVersion >= _version.Value)
                    {
                        return true;
                    }
                }
            }

            return false;
        }
    }
}

