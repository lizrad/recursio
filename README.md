# recursio

Recursio is a top down 1 vs. 1 twin stick shooter where each player tries to capture two points at the same time. To achieve this, each player spawns an afterimage of themselves after each round. This afterimage replays what the player did in the previous round. That way, the player has to cooperate with their previous self to capture both points.

## Play on Hosted Server

`Play Online` takes you to the official development server. Note that it restarts every 15 minutes, so it is unavailable every hour between XX:59 and XX:00, between XX:14 and XX:15, between XX:29 and XX:30, and between XX:44 and XX:45.

Alternatively, you can host a server yourself and enter its IP in the `Play Local` option.

## Controls

```
          DASH                                  FIRE
         _=====_                               _=====_
 SELECT / _____ \                             / _____ \ MELEE
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

## Development Setup

Clone repository including symlinks for addons and shared files

```sh
git clone -c core.symlinks=true https://github.com/lizrad/recursio.git
```

