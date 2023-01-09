# Ton

TON (The Open Network) SDK. It allows:

- Generate a seed from a mnemonic
- Generate public and private keys from a seed
- Generate a v4r2 wallet from a public key
- Parse an address
- Create a transaction which can be submitted using TON API

The library doesn't include an http client

## Installation

The library requires Rust

The package can be installed by adding `ton` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ton, "~> 0.3"}
  ]
end
```

## Docs

The docs can be found at [https://hexdocs.pm/ton](https://hexdocs.pm/ton/Ton.html)

## Author

Ayrat Badykov (@ayrat555)
