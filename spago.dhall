{ name = "my-project"
, dependencies = [ "console", "effect", "psci-support", "html-parser-halogen", "node-fs", "halogen" ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}