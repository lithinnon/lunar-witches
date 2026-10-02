{
  writers,
}:

writers.writePython3Bin "service-deck-helper" {
  flakeIgnore = [
    "E"
    "W"
  ];
} (builtins.readFile ./service-deck-helper.py)
