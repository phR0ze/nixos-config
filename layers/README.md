# Layers
Layers in this context are being defined as reusable compositions of the lower level modules to shape
a generic system without specific host values. In this way we can share configuration across many
hosts and reduce the overhead of maintaining duplicate configuration across the host fleet.

Layers can be built to provide any number of specialized desktop, windowing, application, or service
choices to build a system with a specific purpose e.g. a theater focused system, or a server or your
daily runner desktop. In combination with the final host customization you can build out a number of
fully customizable declarative systems that can be completly rebuilt from on a new blank system in a
matter of minutes.

Each layer has its own purpose and features called out in the layer's nix file header.
