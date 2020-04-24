async function security(args) {
  const { promisify } = require("util");
  const exec = promisify(require("child_process").exec);
  const options = { timeout: 1000 * 5 }
  const cms_output = await exec(`/usr/bin/security ${args.join(" ")}`, options)
    .catch (e => {
      console.error("Could not parse profile");
      console.error(`security exited code ${e.code} executing this command:`);
      console.error(e.cmd)
      console.error(e.stderr);
    });
  return cms_output;
}

exports.security = security;
