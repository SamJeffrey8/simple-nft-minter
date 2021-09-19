
# Simple NFT MInter

  

This project gives a simple nft minter project for using the Plutus Platform.

  

### Cabal+Nix build

  

Alternatively, use the Cabal+Nix build if you want to develop with incremental builds, but also have it automatically download all dependencies.

  

Set up your machine to build things with `Nix`, following the [Plutus README](https://github.com/input-output-hk/plutus/blob/master/README.adoc) (make sure to set up the binary cache!).

  

To enter a development environment, simply open a terminal on the project's root and use `nix-shell` to get a bash shell:

  

```

$ nix-shell

```

  

Otherwise, you can use [direnv](https://github.com/direnv/direnv) which allows you to use your preferred shell. Once installed, just run:

  

```

$ echo "use nix" > .envrc # Or manually add "use nix" in .envrc if you already have one

$ direnv allow

```

  

and you'll have a working development environment for now and the future whenever you enter this directory.

  

The build should not take too long if you correctly set up the binary cache. If it starts building GHC, stop and setup the binary cache.

  

Afterwards, the command `cabal build` from the terminal should work (if `cabal` couldn't resolve the dependencies, run `cabal update` and then `cabal build`).

  

Also included in the environment is a working [Haskell Language Server](https://github.com/haskell/haskell-language-server) you can integrate with your editor.

See [here](https://github.com/haskell/haskell-language-server#configuring-your-editor) for instructions.

  

## The Plutus Application Backend (PAB) example

  

Here, the PAB is configured with one contract, the `SimpleNFT` contract from `.src/Plutus/Contracts/SimpleNFT.hs`.

  

1. Build the PAB executable:

  

```

cabal build simplenft

```

  

2. Run the PAB binary:

  

```

cabal exec -- simplenft

````

  

This will then start up the server on port 9080.

  
  

3. Check what contracts are present:

```

curl -s http://localhost:9080/api/contract/definitions | jq

```

  

You should receive a list of contracts and the endpoints that can be called on them, and the arguments

required for those endpoints.

  

We're interested in the `NFTContract` one.

  

## Connect PAB to Client

  

You can create your own client with any client side framework/libraries and set up proxy to connect with the PAB without CORS issues. You can check out [this repo](https://github.com/SamJeffrey8/simple-nft-minter-site) for the react client of this simple NFT minter.

  

<img src="https://firebasestorage.googleapis.com/v0/b/image-upload-b568f.appspot.com/o/Screenshot%202021-09-19%20095800.jpg?alt=media&token=0e42e441-87b2-4884-a888-bb1b062d2c3e">

  

Thanks!