# WaffleAliyunOss

Aliyun OSS Storage for Waffle

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `waffle_aliyun_oss` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:waffle_aliyun_oss, "~> 0.3.0"}
  ]
end
```

## Configration
All configuration values are stored under the :waffle app key. E.g.
```elixir
config :waffle,
  storage: Waffle.Storage.AliyunOss,
  bucket: "some-bucket",
  region: "cn-hangzhou",
  endpoint: "some.endpoint.com",
  access_key_id: "ALIYUN_ACCESS_KEY_ID",
  access_key_secret: "ALIYUN_ACCESS_KEY_SECRET"
```
You may also set the bucket from an environment variable:
```elixir
config :waffle,
  storage: Waffle.Storage.AliyunOss,
  bucket: {:system, "OSS_BUCKET"},
  region: {:system, "OSS_REGION"},
  endpoint: {:system, "OSS_ENDPOINT"},
  access_key_id: {:system, "ALIYUN_ACCESS_KEY_ID"},
  access_key_secret: {:system, "ALIYUN_ACCESS_KEY_SECRET"}
```

## Documentation
[https://hexdocs.pm/waffle_aliyun_oss](https://hexdocs.pm/waffle_aliyun_oss)
