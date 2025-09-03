defmodule Waffle.Storage.AliyunOss do
  @moduledoc ~S"""
  The module to facilitate integratin with Aliyun OSS through Aliyun.Oss


      config :waffle,
        storage: Waffle.Storage.AliyunOss,
        bucket: {:system, "ALIYUN_OSS_BUCKET"}


  Along with any configuration necessary for Aliyun.Oss.

  [Aliyun.Oss](https://github.com/ug0/aliyun_oss) is used to support Aliyun OSS.

  To store your attachments in Aliyun OSS, you'll need to provide necessary
  configs(bucket, endpoint, and credentials) in your application config:

      config :waffle,
        bucket: "uploads",
        endpoint: "some.endpoint.com",
        access_key_id: "ALIYUN_ACCESS_KEY_ID",
        access_key_secret: "ALIYUN_ACCESS_KEY_SECRET"


  You may also set them from an environment variable:

      config :waffle,
        bucket: {:system, "OSS_BUCKET"},
        endpoint: {:system, "OSS_ENDPOINT"},
        access_key_id: {:system, "ALIYUN_ACCESS_KEY_ID"},
        access_key_secret: {:system, "ALIYUN_ACCESS_KEY_SECRET"}

  You can set them in the uploader definition file to override
  the global configurations like this:
      def bucket, do: "some_custom_bucket_name"
      def endpoint, do: "some_custom_endpoint"
      def access_key_id, do: "your_aliyun_access_key_id"
      def access_key_id, do: "your_aliyun_access_key_secret"


  ## Access Control Permissions

  Waffle defaults all uploads to `default`(Inherit from the bucket).  In cases where it is
  desired to have your uploads public, you may set the ACL at the
  module level (which applies to all versions):

      @acl :public_read

  Or you may have more granular control over each version.  As an
  example, you may wish to explicitly only make public a thumbnail
  version of the file:

      def acl(:thumb, _), do: :public_read

  Supported access control lists for Aliyun OSS are:

  | ACL                          | Permissions Added to ACL                                                        |
  |------------------------------|---------------------------------------------------------------------------------|
  | `:default`                   | Inherit from the Bucket ACL.                                                    |
  | `:private`                   | Owner gets FULL CONTROL. No one else has access rights (default).             |
  | `:public_read`               | Owner gets FULL CONTROL. The others get READ access.                          |
  | `:public_read_write`         | Owner gets FULL CONTROL. The others get READ and WRITE access.            |
  |                              | Granting this on a bucket is generally not recommended.                         |
  For more information on the behavior of each of these, please
  consult Aliyun's documentation for [ACL](https://help.aliyun.com/document_detail/31986.html).
  """

  require Logger

  alias Waffle.Definition.Versioning
  alias Aliyun.Oss.Object.MultipartUpload
  alias WaffleAliyunOss.TaskSupervisor

  @default_expiry_time 60 * 5

  def put(definition, version, {file, scope}) do
    destination_dir = definition.storage_dir(version, {file, scope})
    bucket = oss_bucket(definition)
    key = Path.join(destination_dir, file.file_name)
    acl = definition.acl(version, {file, scope})

    oss_options = [acl: acl]

    do_put(file, {oss_config(definition), bucket, key, oss_options})
  end

  def url(definition, version, file_and_scope, options \\ []) do
    if signed_url?(definition, version, file_and_scope, options) do
      build_signed_url(definition, version, file_and_scope, options)
    else
      build_url(definition, version, file_and_scope, options)
    end
  end

  def delete(definition, version, {file, scope}) do
    definition
    |> oss_config()
    |> Aliyun.Oss.Object.delete_object(
      oss_bucket(definition),
      object_key(definition,
      version,
      {file, scope})
    )

    :ok
  end

  #
  # Private
  #

  # If the file is stored as a binary in-memory, send to OSS in a single request
  defp do_put(file = %Waffle.File{binary: file_binary}, {oss_config, bucket, key, oss_options}) when is_binary(file_binary) do
    Aliyun.Oss.Object.put_object(oss_config, bucket, key, file_binary, headers: req_headers(oss_options))
    |> case do
      {:ok, _res} -> {:ok, file.file_name}
      {:error, error} -> {:error, error}
    end
  end

  @chunk_size 1 * 1024 * 1024
  # Stream the file and upload to OSS as a multi-part upload
  defp do_put(file, {oss_config, bucket, key, oss_options}) do
    acl = Keyword.get(oss_options, :acl)

    case MultipartUpload.upload(oss_config, bucket, key, File.stream!(file.path, [], @chunk_size)) do
      {:ok, _} ->
        Task.Supervisor.start_child(TaskSupervisor, fn -> put_object_acl(oss_config, bucket, key, acl) end)
        {:ok, file.file_name}

      {:error, error} ->
        {:error, error}
    end
  end

  defp put_object_acl(oss_config, bucket, object, acl)
       when acl in [:private, :public, :public_read, :public_read_write] do
    Aliyun.Oss.Object.ACL.put(oss_config, bucket, object, acl_to_header_str(acl))
  end

  defp req_headers(oss_options) do
    Enum.reduce(oss_options, %{}, fn
      {:acl, acl}, acc -> Map.put(acc, "x-oss-object-acl", acl_to_header_str(acl))
      _, acc -> acc
    end)
  end

  defp acl_to_header_str(:public_read), do: "public-read"
  defp acl_to_header_str(:public_read_write), do: "public-read-write"
  defp acl_to_header_str(:private), do: "private"
  defp acl_to_header_str(_), do: "default"

  defp build_url(definition, version, file_and_scope, _options) do
    Path.join(host(definition), object_key(definition, version, file_and_scope))
  end

  defp build_signed_url(definition, version, file_and_scope, options) do
    # Previous waffle argument was expire_in instead of expires_in
    # check for expires_in, if not present, use expire_at.
    # fallback to default, if neither is present.
    expires_in = Keyword.get(options, :expires_in) || Keyword.get(options, :expires_at) || @default_expiry_time

    key = object_key(definition, version, file_and_scope)
    bucket = oss_bucket(definition)

    definition |> oss_config() |> Aliyun.Oss.Object.object_url(bucket, key, expires_in)
  end

  defp signed_url?(_definition, _version, _file_and_scope, options) do
    Keyword.get(options, :signed, false)
  end

  defp object_key(definition, version, file_and_scope) do
    Path.join([
      definition.storage_dir(version, file_and_scope),
      Versioning.resolve_file_name(definition, version, file_and_scope)
    ])
  end

  defp oss_bucket(definition) do
    get_direct_value_or_via_env(definition.bucket)
  end

  defp host(definition) do
    definition
    |> asset_host()
    |> get_direct_value_or_via_env()
  end

  defp asset_host(definiton) do
    case definiton.asset_host() do
      false -> default_host(definiton)
      nil -> default_host(definiton)
      host -> host
    end
  end

  defp default_host(definition) do
    "https://#{oss_bucket(definition)}.#{endpoint(definition)}"
  end

  defp endpoint(definition) do
    get_config_value(definition, :endpoint)
  end

  defp oss_config(definition) do
    Aliyun.Oss.Config.new!(%{
      region: get_config_value(definition, :region),
      endpoint: endpoint(definition),
      access_key_id: get_config_value(definition, :access_key_id),
      access_key_secret: get_config_value(definition, :access_key_secret)
    })
  end

  defp get_config_value(definition, key) do
    if function_exported?(definition, key, 0) do
      apply(definition, key, [])
    else
      :waffle
      |> Application.get_env(key)
      |> get_direct_value_or_via_env()
    end
  end

  defp get_direct_value_or_via_env({:system, key}), do: System.get_env(key)
  defp get_direct_value_or_via_env(value), do: value
end
