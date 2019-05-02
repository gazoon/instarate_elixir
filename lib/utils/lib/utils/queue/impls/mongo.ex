defmodule Utils.Queue.Impls.Mongo do
  alias Utils.Queue.{Consumer, Producer}
  @behaviour Consumer
  @behaviour Producer
  @duplication_code 11_000
  @process_name :mongo_queue

  @config Application.get_env(:utils, :mongo_queue)
  @collection @config[:collection]
  @max_processing_time @config[:max_processing_time]
  require Logger

  @spec child_spec :: tuple
  def child_spec do
    db_config = @config
                |> Keyword.delete(:collection)
                |> Keyword.delete(:max_processing_time)
    options = [name: @process_name, pool: DBConnection.Poolboy] ++ db_config
    Utils.set_child_id(Mongo.child_spec(options), {Mongo, :queue})
  end

  @spec put(integer, any, Keyword.t) :: any
  def put(chat_id, message, opts \\ []) do
    collection = Keyword.get(opts, :queue_name, @collection)
    message_id = UUID.uuid4()
    message_envelope = %{
      created_at: Utils.timestamp_milliseconds(),
      payload: message,
      message_id: message_id
    }
    case Mongo.update_one(
           @process_name,
           collection,
           %{
             "chat_id" => chat_id,
             "msgs.message_id" => %{
               "$ne" => message_id
             }
           },
           %{
             "$set" => %{
               chat_id: chat_id
             },
             "$push" => %{
               msgs: message_envelope
             }
           },
           upsert: true,
           pool: DBConnection.Poolboy
         ) do
      {:error, error = %Mongo.Error{code: code}} when code != @duplication_code -> raise error
      _ -> nil
    end
  end

  @spec get_next :: {any, String.t} | nil
  def get_next do
    processing_id = UUID.uuid4()
    current_time = Utils.timestamp_milliseconds()
    case Mongo.find_one_and_update(
           @process_name,
           @collection,
           %{
             "$or" => [
               %{
                 "processing.started_at" => %{
                   "$exists" => false
                 }
               },
               %{
                 "processing.started_at" => %{
                   "$lt" => current_time - @max_processing_time
                 }
               }
             ]
           },
           %{
             "$set" => %{
               processing: %{
                 started_at: current_time,
                 id: processing_id
               }
             },
             "$pop" => %{
               msgs: -1
             }
           },
           sort: "msgs.0.created_at",
           pool: DBConnection.Poolboy
         ) do
      {:ok, nil} -> nil
      {:ok, doc} ->
        if doc["processing"]["started_at"] < current_time - @max_processing_time do
          Logger.warn("Processing for chat #{doc["chat_id"]} took to long")
        end
        if doc["msgs"] != [] do
          {List.first(doc["msgs"])["payload"], processing_id}
        else
          finish_processing(processing_id)
          nil
        end
      {:error, error} -> raise error
    end
  end

  @spec finish_processing(String.t) :: any
  def finish_processing(processing_id) do
    result = Mongo.delete_one!(
      @process_name,
      @collection,
      %{"msgs" => [], "processing.id" => processing_id},
      pool: DBConnection.Poolboy
    )
    if result.deleted_count == 0 do
      Mongo.update_one!(
        @process_name,
        @collection,
        %{"processing.id" => processing_id},
        %{
          "$unset" => %{
            processing: ""
          }
        },
        pool: DBConnection.Poolboy
      )
    end
  end
end
