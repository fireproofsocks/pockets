# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.6.0

Bumps hex dependencies to latest versions.
Documentation cleanups

## v1.5.0

Bumps hex dependencies to latest versions.
Documentation cleanups

## v1.4.0

Changes the output format for `Pockets.filter/2` and `Pockets.reject/2`: success now
returns an `:ok` tuple with a count of the records removed.

## v1.3.0

Adds support for `Pockets.filter/2` and `Pockets.reject/2` for in-place editing of tables.
Bumps hex dependencies to latest versions.

## v1.2.0

Adds support for `Pockets.incr/4` function
Updates dependencies to latest available

## v1.1.0

Adds `Pockets.exists?/1` function.
Fix for <https://github.com/fireproofsocks/pockets/issues/7> : Now returns :error when table does not exist
Various documentation cleanups.
Downgrades Logger message from warn to debug when a table already exists.
Fixes some improper @specs; various dialyzer fixes
Defines behavior for various functions when table does not exist
Various code linting

## v1.0.0

Tests! Support for `:bag` and `:duplicate_bag`!

## v0.1.0

Initial release. Basic functionality present, but untested!
