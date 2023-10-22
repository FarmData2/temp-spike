const { ESLint } = require("eslint");
const path = require('path');

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
const removeIgnoredFiles = async (files) => {
  const eslint = new ESLint();
  const ignoredFiles = await Promise.all(files.map((file) => eslint.isPathIgnored(file)));
  const filteredFiles = files.filter((_, i) => !ignoredFiles[i]);
  return filteredFiles.join(" ");
};

/*
 * Construct a test command for each .vue file that is staged.
 * The command will use a glob to run all .cy.js files in the 
 * endpoint containing the .vue file.
 */
const getTestCommands = (files) => {
  const testCommands = files.map((file) => {
    if (file.includes("/farm_fd2/")) {
      return "test.bash --fd2 --e2e --dev --glob=" +
        "/modules/farm_fd2/src/entrypoints/" + 
        path.basename(path.dirname(file)) + "/*.cy.js";
    }
    else if (file.includes("/farm_fd2_examples/")) {
      return "test.bash --examples --e2e --dev --glob=" +
        "/modules/farm_fd2_examples/src/entrypoints/" + 
        path.basename(path.dirname(file)) + "/*.cy.js";
    }
    else if (file.includes("/farm_fd2_school/")) {
      return "test.bash --school --e2e --dev --glob=" +
        "/modules/farm_fd2_school/src/entrypoints/" + 
        path.basename(path.dirname(file)) + "/*.cy.js";
    }
    else {
      console.log(".vue file found in unrecognized module.")
      console.log("All .vue files must be in fd2 or fd2_examples or fd2_school.")
    }
  })

  return testCommands
}

// If test file is staged run it.
// If entrypoint file is staged run all tests in that entrypoint
//  use .vue file to get base and build the blob.
// component tests
// unit tests


module.exports = {
  "*": "cspell --no-progress --no-summary --config .cspell.json",
  "*.bash|.githooks/*": "shellcheck",
  "*.md": "markdown-link-check --quiet",
  "*.vue|*.js|*.jsx|*.cjs|*.mjs|*.json|*.md": async (files) => {
    const filesToLint = await removeIgnoredFiles(files);
    return [`eslint --max-warnings=0 ${filesToLint}`];
  },
  "*.vue": (files) => {
    return getTestCommands(files)
  },

}

x  = {

  "*.json": "exit 255",
  "modules/farm_fd2/**/*.cy.js": "echo 'fd2_test'",
  "modules/farm_fd2_examples/**/*.vue": "echo examples_vue",
  "modules/farm_fd2_examples/**/*.cy.js": "echo 'examples_test'",
  "modules/farm_fd2_school/**/*.vue": "echo school_vue",
  "modules/farm_fd2_school/**/*.cy.js": "echo 'school_test'",
  "components/**/*.comp.cy.js":  "echo 'comp_test'",
  "components/**/*.vue": "echo `comp_vue`"
}