
describe "xctestconfig" do

  let(:xcode9config) do
    File.join(IDM::Resources.instance.resources_dir,
              "xctestconfigurations", "xcode9.xctestconfiguration")
  end

  let(:xcode8config) do
    File.join(IDM::Resources.instance.resources_dir,
              "xctestconfigurations", "xcode8.xctestconfiguration")
  end

  context "fails on invalid input" do
    it "fails if file does not exist" do
      args = ["xctestconfig", "path/to/file/does/not/exist"]
      hash = IDM.shell(args)

      expect(hash[:out][/Input file does not exist at path/]).to be_truthy
      expect(hash[:exit_status]).to be == IDM.exit_status(:invalid_arg)
    end

    it "fails if file does not have .xctestconfiguration extension" do
      path = File.join(IDM::Resources.instance.tmp_dir, "file.plist")
      FileUtils.touch(path)

      args = ["xctestconfig", path]
      hash = IDM.shell(args)

      expect(
        hash[:out][/Input file does not have .xctestconfiguration extension/]
      ).to be_truthy
      expect(hash[:exit_status]).to be == IDM.exit_status(:invalid_arg)
    end

    it "fails if file cannot be decoded" do
      path = File.join(IDM::Resources.instance.tmp_dir,
                       "file.xctestconfiguration")
      FileUtils.touch(path)

      args = ["xctestconfig", path]
      hash = IDM.shell(args)

      expect(
        hash[:out][/Could not create an XCTestConfiguration instance by decoding/]
      ).to be_truthy
      expect(hash[:exit_status]).to be == IDM.exit_status(:failure)
    end
  end

  context "reading" do
    it "prints a description of an Xcode 9 template" do
      args = ["xctestconfig", xcode9config]
      hash = IDM.shell(args)

      expect(hash[:out][/XCTestConfiguration/]).to be_truthy
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
    end

    it "prints a description of an Xcode 8 template" do
      args = ["xctestconfig", xcode8config]
      hash = IDM.shell(args)

      expect(hash[:out][/XCTestConfiguration/]).to be_truthy
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
    end
  end

  context "writing" do
    it "writes a plist" do
      path = File.join(IDM::Resources.instance.tmp_dir, "xcode9.plist")
      FileUtils.rm_rf(path)

      args = ["xctestconfig", xcode9config, path]
      hash = IDM.shell(args)

      expect(File.exist?(path)).to be_truthy
      expect(File.read(path)[/sessionIdentifier/]).to be_truthy
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
    end

    it "does not overwrite existing files" do
      path = File.join(IDM::Resources.instance.tmp_dir, "xcode9.plist")
      FileUtils.touch(path)

      args = ["xctestconfig", xcode9config, path]
      hash = IDM.shell(args)

      expect(hash[:out][/File already exists at path/]).to be_truthy
      expect(hash[:exit_status]).to be == IDM.exit_status(:failure)
    end

    it "does overwrite existing files if --overwrite flag is passed" do
      path = File.join(IDM::Resources.instance.tmp_dir, "xcode9.plist")
      FileUtils.touch(path)

      args = ["xctestconfig", xcode9config, path, "--overwrite"]
      hash = IDM.shell(args)

      expect(File.exist?(path)).to be_truthy
      expect(File.read(path)[/sessionIdentifier/]).to be_truthy
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
    end
  end

  context "--print-template" do
    it "prints a plist to stdout" do
      args = ["xctestconfig", "--print-template"]
      hash = IDM.shell(args)

      expect(hash[:out][/NSKeyedArchiver/]).to be_truthy
      expect(hash[:exit_status]).to be == IDM.exit_status(:success)
    end
  end
end
