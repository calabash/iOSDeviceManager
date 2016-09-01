using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Text;

namespace DeviceAgent.iOS.Dependencies
{

    public static class DeploymentManager
    {
        const string HashResource = "DeviceAgent.iOS.Dependencies.hash.txt";
        const string DependenciesResource = "DeviceAgent.iOS.Dependencies.dependencies.zip";
        const string DeviceAgentRunnerApp = "DeviceAgent-Runner.app";

        static Lazy<string> _hash = new Lazy<string>(() => {
            using (var versionStream = MyAssembly.GetManifestResourceStream(HashResource))
            {
                using (var reader = new StreamReader(versionStream, Encoding.UTF8))
                {
                    return reader.ReadToEnd().Trim();
                }
            }
        });

        static Assembly MyAssembly => typeof(DeploymentManager).GetTypeInfo().Assembly;

        public static string HashId =>  _hash.Value;

        public static string PathToiOSDeviceManager { get; } = Path.Combine("bin", "iOSDeviceManager");

        public static string PathToDeviceTestRunner { get; } = Path.Combine("ipa", DeviceAgentRunnerApp);

        public static string PathToSimTestRunner { get; } = Path.Combine("app", DeviceAgentRunnerApp);

        public static void Install(string directory)
        {
            if (!Directory.Exists(directory))
            {
                Directory.CreateDirectory(directory);
            }

            if (Directory.GetFiles(directory).Length > 0)
            {
                throw new InvalidOperationException($"Directory {directory} is not empty");
            }

            var tempZipPath = Path.Combine(directory, "dependencies.zip");

            using (var dependenciesStream = MyAssembly.GetManifestResourceStream(DependenciesResource))
            {
                using (var tempZip = File.Create(tempZipPath))
                {
                    dependenciesStream.CopyTo(tempZip);
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
        }
    }
}

