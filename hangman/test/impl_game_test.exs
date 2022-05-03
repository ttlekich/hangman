defmodule HangmanImplGameTest do
  use ExUnit.Case
  alias Hangman.Impl.Game

  test "new game returns structure" do
    game = Game.new_game()
    assert game.turns_left == 7
    assert game.game_state == :initializing
    assert length(game.letters) > 0
  end

  test "new game returns correct word" do
    game = Game.new_game("wombat")
    assert game.letters == ["w", "o", "m", "b", "a", "t"]
  end

  ### make_move
  test "state doesn't change if a game is won or lost" do
    for state <- [:won, :lost] do
      game = Game.new_game()
      game = Map.put(game, :game_state, state)
      {new_game, _tally} = Game.make_move(game, "x")
      assert new_game == game
    end
  end

  test "a duplicate letter is reported" do
    game = Game.new_game()
    {game, _tally} = Game.make_move(game, "x")
    assert game.game_state != :already_used
    {game, _tally} = Game.make_move(game, "y")
    assert game.game_state != :already_used
    {game, _tally} = Game.make_move(game, "x")
    assert game.game_state == :already_used
  end

  test "we record letters ued" do
    game = Game.new_game()
    {game, _tally} = Game.make_move(game, "x")
    {game, _tally} = Game.make_move(game, "y")
    {game, _tally} = Game.make_move(game, "x")
    assert MapSet.equal?(game.used, MapSet.new(["x", "y"]))
  end

  test "we recognize a letter in the word" do
    game = Game.new_game("wombat")
    {game, _tally} = Game.make_move(game, "w")
    assert game.game_state == :good_guess
  end

  test "we recognize a letter not in the word" do
    game = Game.new_game("wombat")
    {game, _tally} = Game.make_move(game, "x")
    assert game.game_state == :bad_guess
    {game, _tally} = Game.make_move(game, "w")
    assert game.game_state == :good_guess
    {game, _tally} = Game.make_move(game, "")
    assert game.game_state == :bad_guess
  end

  test "can handle a sequence of moves" do
    # hello
    [
      # guess | state | turns_left | letters | letters used
      ["a", :bad_guess, 6, ["_", "_", "_", "_", "_"], ["a"]],
      ["e", :good_guess, 6, ["_", "e", "_", "_", "_"], ["a", "e"]],
      ["x", :bad_guess, 5, ["_", "e", "_", "_", "_"], ["a", "e", "x"]]
    ]
    |> test_sequence_of_moves()
  end

  test "can handle a winning game" do
    # hello
    [
      # guess | state | turns_left | letters | letters used
      ["a", :bad_guess, 6, ["_", "_", "_", "_", "_"], ["a"]],
      ["e", :good_guess, 6, ["_", "e", "_", "_", "_"], ["a", "e"]],
      ["h", :good_guess, 6, ["h", "e", "_", "_", "_"], ["a", "e", "h"]],
      ["a", :already_used, 6, ["h", "e", "_", "_", "_"], ["a", "e", "h"]],
      ["l", :good_guess, 6, ["h", "e", "l", "l", "_"], ["a", "e", "h", "l"]],
      ["o", :won, 6, ["h", "e", "l", "l", "o"], ["a", "e", "h", "l", "o"]]
    ]
    |> test_sequence_of_moves()
  end

  test "can handle a losing game" do
    # hello
    [
      # guess | state | turns_left | letters | letters used
      ["a", :bad_guess, 6, ["_", "_", "_", "_", "_"], ["a"]],
      ["b", :bad_guess, 5, ["_", "_", "_", "_", "_"], ["a", "b"]],
      ["c", :bad_guess, 4, ["_", "_", "_", "_", "_"], ["a", "b", "c"]],
      ["d", :bad_guess, 3, ["_", "_", "_", "_", "_"], ["a", "b", "c", "d"]],
      ["f", :bad_guess, 2, ["_", "_", "_", "_", "_"], ["a", "b", "c", "d", "f"]],
      ["g", :bad_guess, 1, ["_", "_", "_", "_", "_"], ["a", "b", "c", "d", "f", "g"]],
      ["i", :lost, 0, ["_", "_", "_", "_", "_"], ["a", "b", "c", "d", "f", "g", "i"]]
    ]
    |> test_sequence_of_moves()
  end

  def test_sequence_of_moves(script) do
    game = Game.new_game("hello")
    Enum.reduce(script, game, &check_one_move/2)
  end

  def check_one_move([guess, state, turns_left, letters, used], game) do
    {game, tally} = Game.make_move(game, guess)
    assert tally.game_state == state
    assert tally.turns_left == turns_left
    assert tally.letters == letters
    assert tally.used == used
    game
  end
end
