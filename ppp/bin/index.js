#!/usr/bin/env node

const pry = require('pryjs')
const yargs = require("yargs");

const commands = yargs
  .command("parse profile", "parse the profile with 'security cms'", (yargs) => {
    yargs.positional("profile", {
      describe: "path/to/the.mobileprovision"
    })
  }, (argv) => {
    parse_and_archive(argv);
  })
  .command("import directory", "import all .mobileprovision files in directory", (yargs) => {
    yargs.positional("directory", {
      describe: "path/to/the/directory that contains mobileprovision files"
    })
  }, (argv) => {
    parse_and_archive_from_directory(argv);
  })
  .option("verbose", {
    type: "boolean",
    description: "Enable verbose logging"
  })
  .argv;

async function* createAsyncIterable(syncIterable) {
  for (const elem of syncIterable) {
    yield elem;
  }
}

async function parse_and_archive_from_directory(argv) {
  const dir_path = require("path").resolve(argv.directory);
  const fs = require('fs');
  fs.readdir(dir_path, async (err, filenames) => {
    if (err) {
      console.error('Faild reading directory');
    }
    const profile_paths = filenames.filter(filename => {
      return filename.endsWith('.mobileprovision');
    }).map(filename => {
      return `${dir_path}/${filename}`
    }).forEach(async path => {
      // We profiled this and found it worked better than
      //
      // for (const path of profile_paths)
      // for await (const path of profile_paths)
      // for await (const path of createAsyncIterable(profile_paths)
      //
      // ~6 seconds vs ~17 seconds
      //
      // In this implementation. all profiles are read and then all
      // profiles are exported.  We expected that the parse_and_archive
      // would happen in parallel when using for await (...)
      //
      // What we think is happening is that in the first Event Loop tick
      // all calls to parse_and_archive are being registred and none are
      // being executed. In the following Event Loop all calls are made.
      //
      // This has the same runtime performance as forEach
      // for await (const path of createAsyncIterable(profile_paths)) {
      //    setImmediate(async () => {
      //      await parse_and_archive({ profile: path });
      //    });
      //  }
      await parse_and_archive({ profile: path });
    });
  });
}

async function parse_and_archive(argv) {
  const profile_path = require("path").resolve(argv.profile)
  const security = require("../lib/security").security
  const cms_output = await security(["cms", "-D", "-i", `"${profile_path}"`]);
  if (cms_output !== undefined) {
    const plist = require("plist").parse(cms_output.stdout);
    const obj = extract_important_properties(plist);
    obj.path = profile_path;
    //write_json(obj)
    write_sqlite(obj)
    //write_couchdb(obj)
  } else {
    process.exit(1);
  }
}

function prepare_text_value(value) {
  return `'${JSON.stringify(value)}'`;
}

function profile_insert_stmt(obj) {
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

function write_sqlite(obj) {
  const sqlite3 = require("sqlite3").verbose();
  const db = new sqlite3.Database("./ppp.db", (e) => {
    if (e) {
      return console.error(e);
    }
    console.log("Connected ./ppp.db");
  });
  db.serialize(function() {
    const statement = profile_insert_stmt(obj);

    const stmt = db.prepare(statement,
      e => {
        if (e) {
          console.error("Could not prepare:");
          console.error(statement);
          return console.error(e);
        }
        console.log("prepared profile statement");
      });

    stmt.finalize(e => {
      if (e) {
        return console.error(e);
      }
      console.log("finalized statement")
    });
  });

  db.close(e =>  {
    if (e) {
      return console.error(e);
    }
    //console.log('Close the database connection.');
  });
}

function extract_important_properties(plist) {
  return {
    UUID: plist.UUID,
    ProvisionedDevices: plist.ProvisionedDevices,
    ApplicationIdentifierPrefix: plist.ApplicationIdentifierPrefix,
    ExpirationDate: Math.floor(plist.ExpirationDate/1000),
    AppIDName: plist.AppIDName,
    Platform: plist.Platform,
    TeamIdentifier: plist.TeamIdentifier,
    TeamName: plist.TeamName,
    Name: plist.Name,
    Platform: plist.Platform,
    Entitlements: plist.Entitlements
  };
}

async function write_json(obj) {
  const fs = require("fs");
  const uuid = obj.UUID;
  const path = `./db/json/${uuid}.json`
  const jsonString = JSON.stringify(obj);
  await fs.writeFile(path, jsonString, "utf8", function (err) {
    if (err) {
      console.error(`Could not write profile to file: ${path}`);
      console.error(err);
      process.exit(1);
    }
  });
  console.log(`Wrote profile to ${path}`);
}

async function async_stringify(obj) {
  const { promisify } = require("util");
  return await promisify(JSON.stringify)(obj);
}

async function write_couchdb(obj) {
  const db = require("nano")("http://admin:rotate.culprit.exude@127.0.0.1:5984/profiles");
  const id = obj.UUID;
  db.head(id).then(headers => {
    console.log(`Document with ${id} already exists`);
  }).catch(e => {
    if (e.statusCode === 404) {
      db.insert(obj, id).then(body => {
        console.log(body);
      }).catch(e => {
        console.error('insert err:', e);
      });
    } else {
      console.error('head err:', e);
    }
  });
}
