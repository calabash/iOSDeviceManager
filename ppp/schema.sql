DROP DATABASE IF EXISTS ppp;

CREATE DATABASE ppp;

CREATE TABLE profiles (
  UUID TEXT PRIMARY KEY,
  ExpiryDate integer NOT NULL,
  Platform TEXT NOT NULL,
  ApplicationIdentifierPrefix TEXT NOT NULL,
  AppIDName TEXT NOT NULL,
  TeamIdentifier TEXT NOT NULL,
  TeamName TEXT NOT NULL,
  Name TEXT NOT NULL,
  Entitlements TEXT NOT NULL,
  path TEXT NOT NULL
);

CREATE TABLE devices (
  UDID TEXT PRIMARY KEY
);

CREATE TABLE device_profiles (
  profile_id TEXT
  device_id TEXT
  PRIMARY KEY (profile_id, device_id),
  FOREIGN KEY (profile_id)
    REFERENCES profiles (UUID)
      ON DELETE CASCADE
      ON UPDATE NO ACTION,
  FOREIGN KEY (device_id)
    REFERENCES devices (UDID)
      ON DELETE CASCADE
      ON UPDATE NO ACTION
);

-- create certificate table
-- id: autoincrement primary key
-- sha: text unique indexed
-- sha256: text unique indexed
-- common_name: text
-- combined_cert: integer

-- create certificates_profiles table
-- provisioning_profiles.id (references profiles.id)
-- certificates.id (references certificates.id)

-- create app table
-- id: autoincrement primary key
-- sha: text unique index
-- entitlements: text unique index

-- create app_profile table
-- id: autoincrement primary key
-- provisioning_profiles.id (references profiles.id)
-- app.id (references app.id)

