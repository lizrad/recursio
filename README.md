# recursio

Recursio is a top down 1 vs. 1 twin stick shooter where each player tries to capture two points at the same time. To achieve this, each player spawns an afterimage of themselves after each round. This afterimage replays what the player did in the previous round. That way, the player has to cooperate with their previous self to capture both points.

## Download
Download the latest client release [here](https://github.com/lizrad/recursio/releases).

## Play on Hosted Server

`Play Online` takes you to the official development server. Note that it might restart occasionally. If you lose connection to the server just try again after a few moments.
Alternatively, you can host a server yourself and enter its IP in the `Play Local` option.

## Controls

```
          DASH                                  FIRE
         _=====_                               _=====_
   SWAP / _____ \                             / _____ \ MELEE
      +.-'_____'-.---------------------------.-'_____'-.+
     /   |     |  '.                       .'  |  _  |   \
    / ___| /|\ |___ \                     / ___| /_\ |___ \
   / |      |      | ;  __           _   ; | _         _ | ;
   | | <---   ---> | | |__|         |_:> | ||_|       (_)| |
   | |___   |   ___| ;                   ; |___       ___| ;
   |\    | \|/ |    /  _     ___      _   \    |READY|    /|
   | \   |_____|  .','" "', |___|  ,'" "', '.  |_____|  .' |
   |  '-.______.-' /       \      /       \  '-._____.-'   |
   |               |  MOVE |------| LOOK  |                |
   |              /\       /      \       /\               |
   |             /  '.___.'        '.___.'  \              |
   |            /                            \             |
    \          /                              \           /
     \________/                                \_________/
```

Alternatively mouse and keyboard controls are available as well:
- WASD -> Move
- Mouse -> Aim
- LMB -> Fire
- RMB -> Melee
- Space -> Dash
- Tab -> Swap

## Development Setup

Clone repository including symlinks for addons and shared files

```sh
git clone -c core.symlinks=true https://github.com/lizrad/recursio.git
```

