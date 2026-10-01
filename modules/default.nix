# Root dendritic modules aggregator
{ ... }:

{
  imports = [
    ./core
    ./roles
    ./hardware
    ./features
    ./suites
    ./users
  ];
}
