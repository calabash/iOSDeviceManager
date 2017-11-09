
describe "generate-xcappdata" do

  let (:tmp) { IDM::Resources.instance.tmpdir("xcappdata") }
  let (:xcappdata) { File.join(tmp, "New.xcappdata") }

  it "generates a new .xcappdata bundle" do
     args = ["generate-xcappdata", xcappdata]
     hash = IDM.shell(args)

     expect(hash[:out]).to be == xcappdata
     expect(hash[:exit_status]).to be == IDM.exit_status(:success)
     expect(File.exist?(xcappdata)).to be_truthy
  end

  it "fails if xcappdata already exists" do
     FileUtils.mkdir_p(xcappdata)
     args = ["generate-xcappdata", xcappdata]
     hash = IDM.shell(args)

     expect(hash[:exit_status]).to be == IDM.exit_status(:failure)
     error = "Cannot create app data bundle at path"
     expect(hash[:out][/#{error}/]).to be_truthy
  end

  it "fails if existing xcappdata when --overwrite is false" do
     FileUtils.mkdir_p(xcappdata)

     args = ["generate-xcappdata", xcappdata, "--overwrite", "false"]
     hash = IDM.shell(args)

     expect(hash[:exit_status]).to be == IDM.exit_status(:failure)
     error = "Cannot create app data bundle at path"
     expect(hash[:out][/#{error}/]).to be_truthy
  end

  it "overwrites existing xcappdata when --overwrite is true" do
     FileUtils.mkdir_p(xcappdata)
     file = File.join(xcappdata, "file.txt")
     FileUtils.touch(file)

     args = ["generate-xcappdata", xcappdata, "--overwrite", "true"]
     hash = IDM.shell(args)

     expect(hash[:out]).to be == xcappdata
     expect(hash[:exit_status]).to be == IDM.exit_status(:success)
     expect(File.exist?(file)).to be_falsey
  end
end
