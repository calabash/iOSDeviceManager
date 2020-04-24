
describe "Provisioning Profile Parser in JS" do

  it("responds correctly to the --version argument") do
    hash = IDM::PPP.shell(args: ["--version"])
    expect(hash[:out]).to be == "1.0.0"
  end

  it("prints an error when it encounters an error parsing a profile") do
    hash = IDM::PPP.shell(args: ["parse", "Tests/Resources/profiles/a.txt"])
    expect(hash[:out][/security: failed to decode message/]).to be_truthy
    expect(hash[:exit_status]).to be == 1
  end

  it("writes profile as json") do
    hash = IDM::PPP.shell(args: ["parse", "Tests/Resources/profiles/CalabashWildcard.mobileprovision"])
    uuid = "7aa7148f-f245-4d95-898e-dedff226429d"
    path = File.join("ppp", "db", "json", "#{uuid}.json")

    expect(File.exist?(path)).to be == true

    profile = JSON.parse(File.read(path))
    expect(profile["Name"]).to be == "CalabashWildcard"
  end
end
