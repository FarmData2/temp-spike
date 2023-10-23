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
  - use PAT
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
- prettier runs on all files
  - formatting is automatically applied.
- shellcheck on all bash scripts
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
