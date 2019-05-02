use Mix.Config

config :tg_bot,
       bot_name: "InstaRate",
       bot_username: "InstaRateBot",
       mongo_chats: [
         database: "local",
         seeds: ["35.198.77.219:27017"],
       ],
       mongo_scheduler: [
         database: "local",
         seeds: ["35.198.77.219:27017"],
       ],
       mongo_cache: [
         database: "local",
         seeds: ["35.198.77.219:27017"],
       ]

config :utils,
       mongo_queue: [
         database: "local",
         seeds: ["35.198.77.219:27017"],
         collection: "insta_queue",
         max_processing_time: 10000
       ]

config :tg_bot,
       Scheduler.Reader,
       tasks_storage: Scheduler.Impls.Mongo,
       queue: Utils.Queue.Impls.Mongo,
       fetch_delay: 2000

config :tg_bot,
       TGBot.QueueReader,
       queue: Utils.Queue.Impls.Mongo,
       fetch_delay: 2000

config :voting, Voting.Files.Storages.Google,
       bucket_name: "insta-rate-prod"

config :nadia, token: "501332340:AAFqDbDgOx6K4GqfuV0dMlOMW5RzoEObtl4"

config :voting,
       mongo_girls: [
         database: "local",
         seeds: ["35.198.77.219:27017"],
       ],
       mongo_voters: [
         database: "local",
         seeds: ["35.198.77.219:27017"],
       ],
       mongo_profiles: [
         database: "local",
         seeds: ["35.198.77.219:27017"],
       ]
