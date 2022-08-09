# WaffleAliyunOss

Aliyun OSS Storage for Waffle

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `waffle_aliyun_oss` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:waffle_aliyun_oss, "~> 0.2.1"}
  ]
end
```

## Configration
All configuration values are stored under the :waffle app key. E.g.
```elixir
config :waffle, storage: Waffle.Storage.AliyunOss, bucket: "OSS-BUCKET",
```
You may also set the bucket from an environment variable:
```elixir
config :waffle,
  bucket: {:system, "OSS_BUCKET"}
```

In addition, Aliyun.Oss must be configured with the appropriate Aliyun Oss
credentials:
```elixir
config :aliyun_oss,
  endpoint: {:system, "ALIYUN_ENDPOINT"},
  access_key_id: {:system, "ALIYUN_ACCESS_KEY_ID"},
  access_key_secret: {:system, "ALIYUN_ACCESS_KEY_SECRET"}
```

## Documentation
[https://hexdocs.pm/waffle_aliyun_oss](https://hexdocs.pm/waffle_aliyun_oss)
