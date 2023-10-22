/*
 * lint-staged provides the command for each pattern with an explicit
 * list of files.  If one of those files is ignored by .eslintignore 
 * then eslint outputs a warning that it was asked to lint an ignored
 * file and the command fails.  The code below applies the .eslintignore
 * patterns to the list of files before passing them to eslint.
 * 
 * This was adopted/adapted from:
 * https://stackoverflow.com/a/73818629
 */

const { ESLint } = require("eslint");
const path = require('path');

const removeIgnoredFiles = async (files) => {
  const eslint = new ESLint();
  const ignoredFiles = await Promise.all(files.map((file) => eslint.isPathIgnored(file)));
  const filteredFiles = files.filter((_, i) => !ignoredFiles[i]);
  return filteredFiles.join(" ");
};

// const getTestCommandArray = (cmd, files) => {
//   const testCommands = files.map(file => `${cmd} ${file}`);
//   return testCommands;
// }

const getTestCmds = (cmd, files) => {
  return [cmd + "modules/farm_fd2/" + path.basename(path.dirname(file)) + "/*.cy.js"]

  // const testBlobs = files.map((file) => {
  //   if (file.contains("/farm_fd2/") {
  //     return cmd + "modules/farm_fd2/" + path.basename(path.dirname(file)) + "/*.cy.js";
  //   }
  //   else if (file.contains("/farm_fd2_examples/")) {
  //     return cmd + "fd2_examples/" + path.basename(path.dirname(file)) + "/*.cy.js";
  //   }
  //   else if (file.contains("/farm_fd2_school/")) {
  //     return cmd + "fd2_school/" + path.basename(path.dirname(file)) + "/*.cy.js";
  //   }
  //   return null;
  // });
  
  // return testBlobs;
}

// If test file is staged run it.
// If entrypoint file is staged run all tests in that entrypoint
//  use .vue file to get base and build the blob.

module.exports = {
  "*": "cspell --no-progress --no-summary --config .cspell.json",
  "*.bash|.githooks/*": "shellcheck",
  "*.vue|*.js|*.jsx|*.cjs|*.mjs|*.json|*.md": async (files) => {
    const filesToLint = await removeIgnoredFiles(files);
    return [`eslint --max-warnings=0 ${filesToLint}`];
  },
  "*.md": "markdown-link-check --quiet",
  "modules/farm_fd2/**/*.vue": (files) => {
    console.log(files);
    return getTestCmds("test.bash --fd2 --e2e --dev --glob=", files)
  },
  "*.json": "exit 255",
  "modules/farm_fd2/**/*.cy.js": "echo 'fd2_test'",
  "modules/farm_fd2_examples/**/*.vue": "echo examples_vue",
  "modules/farm_fd2_examples/**/*.cy.js": "echo 'examples_test'",
  "modules/farm_fd2_school/**/*.vue": "echo school_vue",
  "modules/farm_fd2_school/**/*.cy.js": "echo 'school_test'",
  "components/**/*.comp.cy.js":  "echo 'comp_test'",
  "components/**/*.vue": "echo `comp_vue`"
}