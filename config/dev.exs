use Mix.Config

config :gedcom_parser, GedcomParser.Repo,[
  adapter: Ecto.Adapters.Postgres,
  database: "gedcom_parser_dev",
  username: "postgres",
  password: "mysecretpassword",
  hostname: "172.17.0.3"
]
