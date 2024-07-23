defmodule Sequin.Sources.PostgresReplicationMessageHandler do
  @moduledoc false
  @behaviour Sequin.Extensions.ReplicationMessageHandler

  alias Sequin.Extensions.PostgresAdapter.Changes.DeletedRecord
  alias Sequin.Extensions.PostgresAdapter.Changes.NewRecord
  alias Sequin.Extensions.PostgresAdapter.Changes.UpdatedRecord
  alias Sequin.Extensions.ReplicationMessageHandler
  alias Sequin.Sources.PostgresReplication
  alias Sequin.Streams

  defmodule Context do
    @moduledoc false
    use TypedStruct

    typedstruct do
      field :stream_id, String.t()
      field :key_prefix, String.t()
      field :key_format, :basic | :with_operation
    end
  end

  def context(%PostgresReplication{} = pr) do
    %Context{
      stream_id: pr.stream_id,
      key_prefix: pr.postgres_database.name,
      key_format: pr.key_format
    }
  end

  @impl ReplicationMessageHandler
  def handle_message(%Context{} = ctx, message) do
    message = message_for_upsert(ctx.key_prefix, message, ctx.key_format)
    Streams.upsert_messages(ctx.stream_id, [message])
  end

  defp message_for_upsert(key_prefix, %DeletedRecord{old_record: old_record} = message, key_format) do
    %{
      key: key_from_message(key_prefix, message, old_record["id"], key_format),
      data:
        Jason.encode!(%{
          data: old_record,
          deleted: true
        })
    }
  end

  # InsertRecord and UpdateRecord
  defp message_for_upsert(key_prefix, %{record: record} = message, key_format) do
    %{
      key: key_from_message(key_prefix, message, record["id"], key_format),
      data:
        Jason.encode!(%{
          data: record,
          deleted: false
        })
    }
  end

  defp key_from_message(key_prefix, message, record_id, key_format) do
    case key_format do
      :with_operation ->
        Enum.join(
          [
            key_prefix,
            Sequin.Key.to_key_token(message.schema),
            Sequin.Key.to_key_token(message.table),
            action(message),
            record_id
          ],
          "."
        )

      :basic ->
        Enum.join(
          [
            key_prefix,
            Sequin.Key.to_key_token(message.schema),
            Sequin.Key.to_key_token(message.table),
            record_id
          ],
          "."
        )
    end
  end

  defp action(message) do
    case message do
      %NewRecord{} -> "insert"
      %UpdatedRecord{} -> "update"
      %DeletedRecord{} -> "delete"
    end
  end
end
