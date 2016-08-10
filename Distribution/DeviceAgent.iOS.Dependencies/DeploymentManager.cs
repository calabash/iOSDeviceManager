using System;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Text;

namespace DeviceAgent.iOS
{

    public static class DeploymentManager
    {
        const string VersionFileName = "version.txt";
        
        static Lazy<Version> _Version = new Lazy<Version>(() => {
            var assembly = typeof(DeploymentManager).GetTypeInfo().Assembly;

            using (var versionStream = assembly.GetManifestResourceStream("DeviceAgent.iOS.version.txt"))
            {
                using (var reader = new StreamReader(versionStream, Encoding.UTF8))
                {
                    return new Version(reader.ReadToEnd());
                }
            }
        });

        public static string PathToiOSDeviceManager => "bin/iOSDeviceManager";

        public static void InstallOrUpdateIfNecessary(string directory)
        {
            if (IsUpToDate(directory))
            {
                return;
            }

            var assembly = typeof(DeploymentManager).GetTypeInfo().Assembly;

            using (var zipStream = assembly.GetManifestResourceStream("DeviceAgent.iOS.dependencies.zip"))
            {
                using (var zipArchive = new System.IO.Compression.ZipArchive(zipStream))
                {
                    foreach (var entry in zipArchive.Entries)
                    {
                        entry.ExtractToFile(Path.Combine(directory, entry.FullName));
                    }
                }
            }

            File.WriteAllText(Path.Combine(directory, VersionFileName), _Version.Value.ToString());
        }

        static bool IsUpToDate(string directory)
        {
            var versionFile = Path.Combine(directory, VersionFileName);

            if (File.Exists(versionFile))
            {
                using (var textReader = File.OpenText(versionFile))
                {
                    var currentVersion = new Version(textReader.ReadToEnd());

                    if (currentVersion >= _Version.Value)
                    {
                        return true;
                    }
                }
            }

            return false;
        }
    }
}

