# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :gedcom_parser, :ecto_repos, [GedcomParser.Repo] 

import_config "#{Mix.env}.exs"
