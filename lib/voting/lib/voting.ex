defmodule Voting do

  alias Voting.Girl
  alias Voting.EloRating
  alias Instagram.Media
  alias Instagram.Client, as: InstagramClient
  alias Voting.InstagramProfiles.Model, as: Profile
  alias Voting.Competitors.Model, as: Competitor
  require Logger

  @config Application.get_env(:voting, __MODULE__)
  @girls_storage @config[:girls_storage]
  @profiles_storage @config[:profiles_storage]
  @voters_storage @config[:voters_storage]

  @celebrities_competition "celebrities"
  @models_competition "models"
  @normal_competition "normal"
  @global_competition "global"
  @celebrity_followers_threshold 500_000
  @model_followers_threshold 10_000

  @max_random_attempt 10

  def global_competition, do: @global_competition
  def normal_competition, do: @normal_competition
  def models_competition, do: @models_competition
  def celebrities_competition, do: @celebrities_competition

  @spec add_girl(String.t) :: {:ok, Profile.t} | {:error, String.t}
  def add_girl(photo_uri) do
    photo_code = InstagramClient.parse_media_code(photo_uri)
    with {:ok, media_info = %Media{is_photo: true}} <- InstagramClient.get_media_info(photo_code),
         followers_number <- InstagramClient.get_followers_number(media_info.owner),
         photo_path <- build_photo_path(media_info.owner),
         {:ok, profile} <- @profiles_storage.add(
           Profile.new(media_info.owner, photo_path, photo_code, followers_number)
         ) do
      Profile.upload_photo(profile, media_info.url)
      choose_competitions(followers_number)
      |> Enum.each(
           fn
             (competition) -> @girls_storage.add_girl(Competitor.new(competition, media_info.owner))
           end
         )
      {:ok, profile}
    else
      {:error, error} -> {:error, error}
      {:ok, %Media{is_photo: false}} -> {:error, "#{photo_code} is not a photo"}
    end
  end

  @spec get_girls_number(String.t) :: integer
  def get_girls_number(competition) do
    @girls_storage.get_girls_number(competition)
  end

  @spec get_next_pair(String.t, String.t) :: {Girl.t, Girl.t} | :error
  def get_next_pair(competition, voters_group_id) do
    attempt = 0
    get_next_pair(competition, voters_group_id, attempt)
  end

  @spec get_girl(String.t, String.t) :: {:ok, Girl.t} | {:error, Stringt.t}
  def get_girl(competition, girl_uri) do
    girl_username = InstagramClient.parse_username(girl_uri)
    case @girls_storage.get_girl(competition, girl_username) do
      {:ok, competitor} ->
        profile = @profiles_storage.get(girl_username)
        {:ok, Girl.combine(competitor, profile)}
      error -> error
    end
  end

  @spec delete_girls([String.t]) :: :ok
  def delete_girls(girl_uris) do
    usernames = Enum.map(girl_uris, &InstagramClient.parse_username/1)
    @girls_storage.delete_girls(usernames)
    @profiles_storage.delete(usernames)
    :ok
  end

  @spec get_top(String.t, integer, [offset: integer]) :: [Girl.t]
  def get_top(competition, number, opts \\ []) do
    offset = Keyword.get(opts, :offset, 0)

    competitors = @girls_storage.get_top(competition, number, offset)
    build_girls(competitors)
  end

  @spec vote(String.t, String.t, String.t, String.t, String.t)
        :: {:ok, {Girl.t, Girl.t}} | {:error, String.t}
  def vote(competition, voters_group_id, voter_id, winner_username, loser_username) do
    with :ok <- @voters_storage.try_vote(
      competition,
      voters_group_id,
      voter_id,
      winner_username,
      loser_username
    ),
         {:ok, winner} <- @girls_storage.get_girl(competition, winner_username),
         {:ok, loser} <- @girls_storage.get_girl(competition, loser_username) do
      {winner, loser} = process_vote(winner, loser)
      @girls_storage.update_girl(winner)
      @girls_storage.update_girl(loser)
      {:ok, build_girls_tuple([winner, loser])}
    else
      error -> error
    end
  end

  @spec process_vote(Competitor.t, Competitor.t) :: {Competitor.t, Competitor.t}
  defp process_vote(winner, loser) do
    {new_winner_rating, new_loser_rating} = EloRating.recalculate(winner.rating, loser.rating)
    winner = %Competitor{
      winner |
      rating: new_winner_rating,
      matches: winner.matches + 1,
      wins: winner.wins + 1
    }
    loser = %Competitor{
      loser |
      rating: new_loser_rating,
      matches: loser.matches + 1,
      loses: loser.loses + 1
    }
    {winner, loser}
  end

  @spec get_next_pair(String.t, String.t, integer) :: {Girl.t, Girl.t} | :error
  defp get_next_pair(competition, voters_group_id, attempt)

  defp get_next_pair(competition, voters_group_id, _attempt = @max_random_attempt) do
    Logger.warn("Can't get girls for #{voters_group_id} in competition #{competition}")
    :error
  end

  defp get_next_pair(competition, voters_group_id, attempt) do
    {competitor_one, competitor_two} = @girls_storage.get_random_pair(competition)
    if @voters_storage.new_pair?(
         competition,
         voters_group_id,
         competitor_one.username,
         competitor_two.username
       ) do
      build_girls_tuple([competitor_one, competitor_two])
    else
      get_next_pair(competition, voters_group_id, attempt + 1)
    end
  end

  @spec build_girls_tuple([Competitor.t]) :: {Girl.t, Girl.t}
  defp build_girls_tuple(competitors) do
    girls = build_girls(competitors)
    if  length(girls) == 2,
        do: List.to_tuple(girls), else: raise "It only makes sence to use 2 elems tuple"
  end

  @spec build_girls([Competitor.t]) :: [Girl.t]
  defp build_girls(competitors) do
    competitor_usernames = for c <- competitors, do: c.username
    profiles = @profiles_storage.get_multiple(competitor_usernames)
    profiles_mapping = for p <- profiles, into: %{}, do: {p.username, p}
    if Enum.count(competitors) != Enum.count(profiles_mapping) do
      raise "Number of profiles is not equal to competitiors #{inspect competitor_usernames}"
    end
    Enum.map(
      competitors,
      fn (competitor) ->
        profile = Map.fetch!(profiles_mapping, competitor.username)
        Girl.combine(competitor, profile)
      end
    )
  end

  @spec build_photo_path(String.t) :: String.t
  defp build_photo_path(username), do: username <> "-" <> UUID.uuid4()

  @spec choose_competitions(integer) :: [String.t]
  defp choose_competitions(followers_number) do
    competition_by_followers = cond do
      followers_number < @model_followers_threshold -> @normal_competition
      followers_number < @celebrity_followers_threshold -> @models_competition
      true -> @celebrities_competition
    end
    [@global_competition, competition_by_followers]
  end
end
