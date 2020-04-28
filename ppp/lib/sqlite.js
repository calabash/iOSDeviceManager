
function prepare_text_value(value) {
  // TODO Does calling stringify on Strings make this slower
  return `'${JSON.stringify(value)}'`;
}

function profile_insert_statement(obj) {
  const columns = [
    "UUID",
    "ExpirationDate",
    "Platform",
    "ApplicationIdentifierPrefix",
    "AppIDName",
    "TeamIdentifier",
    "TeamName",
    "Name",
    "Entitlements",
    "path"
  ].join(",");

  const values = [
    prepare_text_value(obj.UUID),
    obj.ExpirationDate,
    prepare_text_value(obj.Platform),
    prepare_text_value(obj.ApplicationIdentifierPrefix),
    prepare_text_value(obj.AppIDName),
    prepare_text_value(obj.TeamIdentifier),
    prepare_text_value(obj.TeamName),
    prepare_text_value(obj.Name),
    prepare_text_value(obj.Entitlements),
    prepare_text_value(obj.path)
  ].join(",");

  return `INSERT INTO profiles (${columns}) VALUES (${values})`;
}

function device_profiles_statement(obj) {
  const devices = obj.ProvisionedDevices;

  if (devices === undefined) {
    console.log(`Profile with ${obj.Name} does not have devices - skipping insert.`);
    return devices;
  }
  const values = devices.map(udid => {
    return `(${prepare_text_value(obj.UUID)}, ${prepare_text_value(udid)})`;
  });
  return `INSERT INTO device_profiles (profile_id, device_id) VALUES ${values}`;
}

function insert(db, statement, table_name) {
  if (statement === undefined) {
    return;
  }

  const stmt =  db.prepare(statement, e => {
    if (e) {
      console.error(`Could not prepare for ${table_name}:`);
      console.error();
      console.error(statement);
      console.error();
      console.error(e);
      process.exit(1);
    }
  });

  db.run(stmt.sql, e => {
    if (e) {
      console.error(`Could not insert into ${table_name}:`);
      console.error();
      console.error(statement);
      console.error();
      console.error(e);
      process.exit(1);
    }
  });

  stmt.finalize(e => {
    if (e) {
      console.error(`Could not finalize insert into ${table_name}`);
      console.error(e);
      process.exit(1);
    }
  });
}

function write_sqlite(obj) {
  const sqlite3 = require("sqlite3");
  // TODO: optimization? We are opening the database everytime we process a new profile
  const db_path = require("path").resolve("./db/sqlite/ppp.db");
  const db = new sqlite3.Database(db_path, (e) => {
    if (e) {
      console.error(`Could not open db at path: ${db_path}`);
      console.error(e);
      process.exit(1);
    }
    //console.log(`Connected to ${db_path}`);
  });

  db.serialize(async function() {
    const statement = `SELECT UUID FROM profiles WHERE uuid=${prepare_text_value(obj.UUID)}`;
    db.get(statement, (err, row) => {
      if (err) {
        console.error(err);
        process.exit(1);
      }
      if (row) {
        console.log(`${obj.UUID} already exists in db`);
      } else {
        insert(db, profile_insert_statement(obj), "profiles");
        insert(db, device_profiles_statement(obj), "device_profiles");
      }
    });
  });

  db.close(e =>  {
    if (e) {
      console.error(e);
      process.exit(1);
    }
  });
}

exports.write_sqlite = write_sqlite;

