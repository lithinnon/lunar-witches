# ADR 0009: Custom Desktop Protocol Handlers & Steam Artwork (`sgdboop`)

> **Status:** Accepted  
> **Date:** 2026-09-30  
> **Scope:** Desktop Integration & Protocol Handlers  

---

## 1. Context & Problem

Custom non-Steam game shortcuts require banners, hero images, logos, and grid art to match the native Steam Big Picture and desktop UI. Manually downloading images from SteamGridDB and naming them to Steam's internal CRC32 app IDs is tedious and error-prone.

## 2. Decision

We integrated `sgdboop` into the user environment (`modules/users/nnon/desktop.nix`):
1. Packaged via `pkgs.sgdboop`.
2. Associated with the custom MIME protocol `x-scheme-handler/sgdb` (`com.steamgriddb.SGDBoop.desktop`).
3. Clicking "Boop" on SteamGridDB browser pages directly triggers the local helper, which calculates the Steam game hash and injects assets directly into `~/.local/share/Steam/userdata/<id>/config/grid/`.

## 3. Consequences

- One-click seamless artwork updates for all game launchers and emulators.
- Fully declarative MIME association across desktop sessions.
