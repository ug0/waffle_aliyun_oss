defmodule WaffleAliyunOss.MixProject do
  use Mix.Project

  def project do
    [
      app: :waffle_aliyun_oss,
      version: "0.3.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {WaffleAliyunOss.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:waffle, "~> 1.0"},
      {:aliyun_oss, "~> 2.0"},
      {:ex_doc, "~> 0.20", only: :dev}
    ]
  end

  defp description do
    """
    Aliyun OSS Storage for Waffle
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ug0/waffle_aliyun_oss"},
      source_urL: "https://github.com/ug0/waffle_aliyun_oss",
      homapage_url: "https://github.com/ug0/waffle_aliyun_oss"
    ]
  end

  defp docs do
    [
      main: "Waffle.Storage.AliyunOss"
    ]
  end
end
