# mydav

I was looking for a WebDAV server, but at the time of writing (2023-07-24) I
found:

- The popular go implementation archived 2022-09: <https://github.com/hacdias/webdav>
- The rust implementation unmaintained since 2022-05: <https://github.com/miquels/webdav-server-rs>
- The nginx extension unmaintained since 2018-12: <https://github.com/arut/nginx-dav-ext-module>

I also tried [SeaweedFS](https://github.com/seaweedfs/seaweedfs),
but I found that it was too complex to quickly debug issues I was running into.

[messense/dav-server-rs] is actively maintained (at the time of writing),
but did not provide a server implementation.

This is my server implementation using [messense/dav-server-rs] until I find
a more mature solution.

[messense/dav-server-rs]: https://github.com/messense/dav-server-rs

## Usage

This is designed to be used with [NixOS], but should work with most Linux
distributions.

- Add this repository to your flake inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    mydav.url = "github:newam/mydav";
    mydav.inputs.nixpkgs.follows = "nixpkgs";
    dp800.inputs.treefmt.follows = "";
  };
}
```

- Add `mydav.overlays.default` to `nixpkgs.overlays`.
- Import the `mydav.nixosModules.default` module.
- Configure.

[NixOS]: https://nixos.org/
