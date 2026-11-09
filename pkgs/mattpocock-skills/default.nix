# Builds a flat, read-only skill pool from the mattpocock/skills repo.
#
# Input source layout (bucketed):
#   <src>/skills/engineering/<name>/SKILL.md
#   <src>/skills/productivity/<name>/SKILL.md
#
# Output layout (flattened, one level deep — what every harness's scanner expects):
#   $out/skills/<name>/SKILL.md
#
# Producing a flattened pool here is the whole trick: Claude Code, Antigravity
# and Pi all scan `skills/<name>/SKILL.md` one level deep and would see
# `engineering/` as a fake skill if pointed at the bucketed source. `cp -rL`
# dereferences any repo-internal symlinks so the store copy is self-contained.
{ pkgs, src }:

pkgs.runCommand "mattpocock-skills" { } ''
  mkdir -p $out/skills
  for dir in \
    ${src}/skills/engineering/* \
    ${src}/skills/productivity/*
  do
    [ -f "$dir/SKILL.md" ] || continue
    name="$(basename "$dir")"
    mkdir -p "$out/skills/$name"
    cp -rL "$dir/." "$out/skills/$name/"
  done
  echo "flattened $(find $out/skills -mindepth 1 -maxdepth 1 -type d | wc -l) skills into $out/skills"
''
