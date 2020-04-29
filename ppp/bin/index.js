#!/usr/bin/env node

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
      // async function* createAsyncIterable(syncIterable) {
      //   for (const elem of syncIterable) {
      //     yield elem;
      //   }
      // }
      //
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
    write_json(obj)
    write_sqlite(obj)
    write_couchdb(obj)
  } else {
    process.exit(1);
  }
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

  // This is slightly faster than always writing
  try {
    // File already exists
    await fs.promises.access(path);
  } catch (error) {
    // File does not exist
    const jsonString = JSON.stringify(obj);
    await fs.writeFile(path, jsonString, "utf8", function (err) {
      if (err) {
        console.error(`Could not write profile to file: ${path}`);
        console.error(err);
        process.exit(1);
      }
    });
  }
}

async function write_sqlite(obj) {
  const sqlite = require("../lib/sqlite");
  sqlite.write_sqlite(obj);
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
