(lang dune 3.16)

(name patchlings)

(generate_opam_files true)

(source
 (github username/reponame))

(authors "Author Name")

(maintainers "Maintainer Name")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name patchlings)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends ocaml (dune (= 3.18.2)) utop core yojson cmdliner minttea spices leaves wcwidth)
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
