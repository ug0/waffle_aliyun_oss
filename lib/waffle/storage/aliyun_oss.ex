defmodule Waffle.Storage.AliyunOss do
  require Logger

  alias Waffle.Definition.Versioning
  alias Aliyun.Oss.Object.MultipartUpload

  @default_expiry_time 60 * 5

  def put(definition, version, {file, scope}) do
    destination_dir = definition.storage_dir(version, {file, scope})
    bucket = oss_bucket(definition)
    key = Path.join(destination_dir, file.file_name)

    # TODO: Accept custom options
    oss_options = []

    do_put(file, {bucket, key, oss_options})
  end

  def url(definition, version, file_and_scope, options \\ []) do
    if signed_url?(definition, version, file_and_scope, options) do
      build_signed_url(definition, version, file_and_scope, options)
    else
      build_url(definition, version, file_and_scope, options)
    end
  end

  def delete(definition, version, {file, scope}) do
    oss_bucket(definition)
    |> Aliyun.Oss.Object.delete_object(object_key(definition, version, {file, scope}))

    :ok
  end

  #
  # Private
  #

  # If the file is stored as a binary in-memory, send to OSS in a single request
  defp do_put(file = %Waffle.File{binary: file_binary}, {bucket, key, _oss_options}) when is_binary(file_binary) do
    Aliyun.Oss.Object.put_object(bucket, key, file_binary)
    |> case do
      {:ok, _res}     -> {:ok, file.file_name}
      {:error, error} -> {:error, error}
    end
  end

  @chunk_size 1 * 1024 * 1024
  # Stream the file and upload to OSS as a multi-part upload
  defp do_put(file, {bucket, key, _oss_options}) do
    case MultipartUpload.upload(bucket, key, File.stream!(file.path, [], @chunk_size)) do
      {:ok, _} -> {:ok, file.file_name}
      {:error, error} -> {:error, error}
    end
  end

  defp build_url(definition, version, file_and_scope, _options) do
    Path.join(host(definition), object_key(definition, version, file_and_scope))
  end

  defp build_signed_url(definition, version, file_and_scope, options) do
    # Previous waffle argument was expire_in instead of expires_in
    # check for expires_in, if not present, use expire_at.
    # fallback to default, if neither is present.
    expires_in = Keyword.get(options, :expires_in) || Keyword.get(options, :expires_at) || @default_expiry_time
    expires =
      DateTime.utc_now()
      |> DateTime.to_unix()
      |> Kernel.+(expires_in)

    key = object_key(definition, version, file_and_scope)
    bucket = oss_bucket(definition)

    Aliyun.Oss.Object.object_url(bucket, key, expires)
  end

  defp signed_url?(definition, version, file_and_scope, options) do
    definition.acl(version, file_and_scope) not in [:public_read, :public_read_write] or
      Keyword.get(options, :signed, false)
  end

  defp object_key(definition, version, file_and_scope) do
    Path.join([
      definition.storage_dir(version, file_and_scope),
      Versioning.resolve_file_name(definition, version, file_and_scope)
    ])
  end

  defp oss_bucket(definition) do
    case definition.bucket() do
      {:system, env_var} when is_binary(env_var) -> System.get_env(env_var)
      name -> name
    end
  end

  defp host(definition) do
    case asset_host(definition) do
      {:system, env_var} when is_binary(env_var) -> System.get_env(env_var)
      url -> url
    end
  end

  defp asset_host(definiton) do
    case definiton.asset_host() do
      false -> default_host(definiton)
      nil -> default_host(definiton)
      host -> host
    end
  end

  defp default_host(definition) do
    "https://#{oss_bucket(definition)}.#{endpoint()}"
  end

  defp endpoint do
    Application.fetch_env!(:aliyun_oss, :endpoint)
  end
end
