- In Docker Desktop -> Settings -> Advanced
  - Enable: Allow the default Docker socket to be used
  - if it exists... depends on version.

## Install

- Clone repo
- cd FarmData2/bin
- ./fd2-up.bash
  - Wait for Message: `FarmData2 development environment started`
    - Spinner
    - Will take a little time the first time.
- Open TigerVNC
- Connect to `localhost:5901`
- open terminal
  - Logged in as `fd2dev` with password `fd2dev`
  - have sudo privileges
- cd FarmData2
- npm install
- Configure git:
  - git config --global user.email "you@example.com"
  - git config --global user.name "Your Name"
- Open Codium
  - Open FarmData2 folder
  - Check "Trust the authors of all files in the parent folder fd2dev"
  - Click "Yes, I trust the authors"
- Create GH PAT
  - Permissions of 'repo', 'read:org', 'workflow'
  - copy PAT somewhere safe
- Log into gh
  - gh auth login --hostname GitHub.com --git-protocol https
  - use PAT as password.
- Install sample Database

  - installDB.bash
    - choose top release (1)
    - choose sample.db database (2)
    - enter fd2dev password

- Test farmOS

  - Visit `http://farmos` and login.

  Credentials:

  - Login:
    - User: admin
    - Pass: admin
  - Login:
    - User: manager1 (or 2)
    - Pass: farmdata2
  - Login:
    - User: worker1 (or 2, 3, 4, 5)
    - Pass: farmdata2
  - Login:
    - User: guest
    - Pass: farmdata2

Doesn't really belong here ... but here for now...

## Connecting

- Dev server

  - npm run dev:fd2 (or examples, or school)
  - localhost:5173/fd2/main/ (or fd2_examples/main/ or fd2_school/main/)
    - note: trailing / is important!
    - changes are live

- Preview server

  - npm run preview:fd2 (or examples, or school)
  - localhost:4173/fd2/main/ (or fd2_examples/main/ or fd2_school/main/)
    - note: trailing / is important!
    - changes are not live (tests bundling)
      - use npm run watch:fd2 (or examples, or school) to see changes live

- Live server

  - npm run build:fd2 (or examples, or school)
  - farmos
  - changes are not live (running from build)
    - use npm run watch:fd2 (or examples, or school) to see changes live

## Pre-commit checks

- npm run check:staged
- If tests do not complete... fd2-down.bash, fd2-up.bash

  - usually a zombie dev server out there.

- cspell runs on all files
  - use a known word or add to .fd2-cspell.txt if unavoidable.
- prettier runs on all files that it knows how to format.
  - formatting is automatically applied.
- shellcheck runs on all bash scripts
- shfmt runs on all bash scripts
  - formatting is automatically applied.
- markdown-link-check on all md files
- eslint on all .vue .js .jsx .cjs .mjs .json .md
- e2e tests (in modules)
  - all cy.js tests in entrypoint directory for a staged .vue
  - all .cy.js files that are staged.
- component tests (in components)
  - all comp.cy.js tests in component directory for a staged .vue
  - all comp.cy.js files that are staged.
- unit tests (in library)
  - all unit.cy.js tests in library directory for a staged .js
  - all unit.cy.js tests that are staged.

### Development Workflow

To change, modify, update, add a database:

- Prerequisites:
  - Fork the `FD2-SampleDBs` upstream repository
  - Clone your fork into the FarmData2 Development Environment

1. Ensure that your `development` branch is synchronized with the `upstream`
2. Create a new feature branch from the `development` branch
3. Make and test changes in your feature branch
4. Commit to your feature branch:
   - The changes you have made to the code.
   - The newly created database files (e.g. `db.base.tar.gz`)
5. Pull and merge any new changes to the `development` branch into your feature branch
6. Create a pull request to the `development` branch in the upstream

A maintainer will:

1. Review your pull request and provide feedback
2. If/when appropriate squash merge your pull request into the `development` branch
   - The squash merge commit message must be a conventional commit message.
     - This will create a pre-release `vX.Y.Z-development.n`
       - X.Y.Z is the semantic version of the next release if created at the moment
       - n is a sequence number for pre-releases with the same semantic version number.

## Creating a GitHub Release of the farm_fd2 Module

When changes warranting a new release have been added to the `development` branch a maintainer will create a new release by:

1. Updating the `production` and `development` branches from the upstream.
2. Fast-forward merging the latest `development` branch into the `production` branch
3. Pushing the `production` branch to the upstream
   - This will create a new release `vX.Y.Z`
     - X.Y.Z is the semantic version of the release
     - All but the most recent `development` pre-release will be deleted
     - The `CHANGELOG.md` file in the `production` branch is updated with the changes added
     - The `production` branch is _backmerged_ into the `development` branch

Then you will need to:

1. Update the `production` and `development` branches from the upstream to get the backmerged `CHANGELOG.md` file.

## Creating a Drupal Release of the farm_fd2 Module

This is done via drupal.org

- See: <https://www.drupal.org/docs/develop/git/git-for-drupal-project-maintainers/creating-a-project-release>
- See: <https://www.drupal.org/project/farmdata2/git-instructions>

- clone <https://git.drupalcode.org/project/farmdata2>
- crete branch for release
- Copy farm_fd2/dist into branch
- commit changes
- Create tag
- Push tag
- Go to <https://git.drupalcode.org/project/farmdata2>
- Scroll to bottom
  - Click "Add new release"
  - Fill out the form
