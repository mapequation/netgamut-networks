# netgamut-networks: web mirror

This branch holds the web mirror: Netzschleuder, KONECT and SNAP networks as
gzipped Pajek files, and the `index.json` manifest that lists them.
`netgamut export-networks` builds it, run monthly by
`.github/workflows/mirror.yml` on `main`. The README on `main` explains what is
here, how the files are served and how to cite them.
