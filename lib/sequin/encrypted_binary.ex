defmodule Sequin.EncryptedBinary do
  @moduledoc false
  use Cloak.Ecto.Binary, vault: Sequin.Vault

  @type t :: String.t()
end