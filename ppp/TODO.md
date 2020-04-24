- [x] read a profile
- [x] parse and save the important parts to JSON file using UUID
- [ ] (ditto)                               sqlite
- [x] (ditto)                               couchdb

## info to capture

string UUID - file name that we save to <UUID>.json
array[string] ProvisionedDevices
date ValidUntilDate # key date. value is an array and we want the last date
string ApplicationIdentifierPrefix
string AppIDName
array[string?] DeveloperCertificates - certificates must be parsed
string Platform
array[string] TeamIdentifier
string TeamName
string Name
string Platform
string Entitlements;
