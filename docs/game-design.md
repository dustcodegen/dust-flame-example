# Syntax Catch design notes

The learning task is recognizing the next token in an authored program and
reconstructing its order. The movement task is catching that token while
letting other tokens pass. A valid token can still be wrong at the current
position. The game does not execute code or assess programming proficiency.

## Research and design choices

[GameFlow, Sweetser and Wyeth (2005)](https://doi.org/10.1145/1077246.1077253)
identifies clear goals, feedback, control, and suitable challenge as elements of
player enjoyment. [Kiili's experiential gaming model (2005)](https://doi.org/10.1016/j.iheduc.2004.12.001)
also connects clear goals, immediate feedback, and challenge matched to skill.
These models inform the choices below; they do not validate this particular game.

| Principle | Application in this game |
| --- | --- |
| Clear goal | Full code stays visible, collected tokens change color, and NEXT names the required token. |
| Player control | Choose a language and read its code in the ready state; selection does not start the rain. |
| Readable challenge | Individual drops use a fixed beginner pace, without a speed increase for entering a new language. |
| Fair recovery | Skipping costs nothing, missed required tokens return, and wrong catches preserve code progress. |
| Immediate feedback | Catch text names what happened; a catcher flash reinforces correct and wrong catches. |

[Moreno (2004)](https://doi.org/10.1023/B:TRUC.0000021811.66966.1d)
compared explanatory and corrective feedback in discovery-based multimedia.
It motivates making mistakes informative. Our short `Caught X; need Y` feedback
identifies the mismatch but does not explain a language rule, so it should not
be presented as equivalent to that study's explanatory feedback.

## Current rules and tuning

- One token spawns every 0.75 seconds and falls at 190 board pixels per second.
  Three horizontal lanes keep pieces separate and give keyboard movement clear
  destinations. Several staggered drops can remain visible together. A stalled
  frame advances simulation by at most 100 milliseconds to limit catch cascades.
- Each spawn has a one-in-three chance of offering the required token, and two
  consecutive distractors force the next spawn to offer it. While the target
  stays unchanged, it is offered within three spawns, with no more than two
  distractors between offers. Advancing the code resets that counter for its
  new target; existing falling pieces remain part of the rain.
- Catching the exact next token adds one point and advances the code. Catching
  another token loses one of three lives. Passing any token has no penalty.
- Three mistakes end the session. Progress and points remain visible until
  restart. Completing code pauses the rain before the next challenge.
- Language tiles select authored challenges only while ready. Unknown language
  selections and changes during play are rejected. Choosing does not autoplay.
- Eight short examples cover six languages. New language content uses the same
  token-and-whitespace format; no language-specific gameplay branch is needed.
  Authored examples require separate syntax checks with the relevant tools.

The timing, frame cap, lives, target frequency, and lane geometry are design
hypotheses and playtest targets, not numeric recommendations from these papers.
No adaptive difficulty or additional reward system is included.

The charcoal terminal style keeps amber for the current target and icy cyan for
collected code. Line numbers and a progress bar anchor the complete program;
trails show falling motion, and the bracket catcher connects play to code. These
visual choices are design hypotheses, not findings established by the papers.

## Manual playtest checks

- Ask a new player to explain NEXT and the skip rule before starting. Confirm
  that choosing a language and reading its code cannot lose a life or start rain.
- Try keyboard, tap, and drag controls. Check that the target can be reached and
  wrong pieces can be avoided without an unintended catch.
- Deliberately miss the required token, then catch it when it returns. Confirm
  that progress, lives, and points do not change during the skipped drops.
- Compare novice and experienced players for readability, waiting time, and
  difficulty. Observe mistakes and ask what caused them before changing pace.
- Check whether players understand the mismatch feedback and distinguish exact
  template matching from syntax that could be valid in another program.

Learning transfer, long-term retention, and enjoyment need player studies.
