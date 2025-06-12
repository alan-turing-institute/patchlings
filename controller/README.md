`controller path_asm path_wrapper` start a process that listen to `stdin`. It reads from `stdin` a string that defines the neighbourhoods the players, executes Assembly functions to process each of them and to return for each player what they intend to do next. It then goes back to listening to `stdin` for the next round of environments.

`path_asm` needs to be an absolute path, probably `pwd() + "/asm"`. It is the folder that holds the assembly source code files for the players. They *must* be named `0.s`, `1.s`, etc., where the numbering corresponds to the players. There must be as many files as there are players.

`path_wrapper` can be relative, and points to the folder `wrapper` that includes a bit of rust code that wraps around each Assembly function, to make them callable. It is typically `./wrapper/`.

An additional third argument `--debug` can be provided to start `controller` in debug mode, in which case it prints out more information about inputs, outputs, and errors.

The format of the input that `controller` reads from `stdin` is a single line, that is a comma separated list of strings. One string per player, and one line per round in the game. Each player string should can be up to 16 ASCII characters long. In strings shorter than 16 characters is padded with zero bytes. The total of 16 bytes are then interpreted as two `uint64`s and passed onto each Assembly function as the values in the first two registers, `x0` and `x1`.

Each Assembly function must return its intended action by writing it to the register `x0` and calling `ret`. The value should be a single byte describing an ASCII character. This is then passed back to the OCaml game through `controller'`s `stdout`, as a single-character string. The OCaml game then interprets the character as an intended action.

The meaning of the characters is defined in the OCaml game. At the time of writing (2025-06-12 09:39 BST) the input to controller consists of 9 characters, one for each cell in the neighbourhood of a player. They are numbered as
```
076
185
234
```
where 8, the last one, is the cell that the player is standing in.

So, for instance, if there were two players, `controller` might receive the following line as input:
```
OOOOOOOOF,PPPPPFFFF
```
This would mean that the first player is on a forest tile (`F`) surrounded by ocean (`O`) on all sides, and the second player has plains (`P`) to the West and South, and forest to the East and North, and directly under it. These strings would then be passed on to the assembly functions defined in `asm/0.s` and `asm/1.s`, respectively, in the first two registers. The first register holds the first 8 characters/bytes, i.e. the surroundings, and the second one holds the cell the character is on in its first byte and zeros in the rest.

The first assembly program might then return, in its `x0` register, the value `.`, indicating it wants to stand still, and the second one might return `N`, indicating it wants to go North.

The meanings of the return values are currently defined in `lib/intent.ml` and the meanings of the cell encodings in `lib/board.ml`, soon to be moved to `lib/environment.ml`.
