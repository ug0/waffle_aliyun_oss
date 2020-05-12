# WaffleAliyunOss

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `waffle_aliyun_oss` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:waffle_aliyun_oss, "~> 0.1.0"}
  ]
end
```

## Configration
All configuration values are stored under the :waffle app key. E.g.
```elixir
config :waffle, storage: Waffle.Storage.AliyunOss, bucket: "OSS-BUCKET",
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/waffle_aliyun_oss](https://hexdocs.pm/waffle_aliyun_oss).

