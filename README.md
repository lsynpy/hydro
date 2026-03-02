# Hydro

## Installation

Install with [Fisher](https://github.com/jorgebucaran/fisher):

```console
fisher install lsynpy/hydro
```

## Configuration

Modify variables using `set --universal` from the command line or `set --global` in your `config.fish` file.

### Symbols

| Variable                  | Type   | Description                     | Default |
| ------------------------- | ------ | ------------------------------- | ------- |
| `hydro_symbol_start`      | string | Prompt start symbol.            |         |
| `hydro_symbol_prompt`     | string | Prompt symbol.                  | `❱`     |
| `hydro_symbol_git_dirty`  | string | Dirty repository symbol.        | `•`     |
| `hydro_symbol_git_ahead`  | string | Ahead of your upstream symbol.  | `↑`     |
| `hydro_symbol_git_behind` | string | Behind of your upstream symbol. | `↓`     |

### Colors

> Any argument accepted by [`set_color`](https://fishshell.com/docs/current/cmds/set_color.html).

| Variable               | Type  | Description                    | Default              |
| ---------------------- | ----- | ------------------------------ | -------------------- |
| `hydro_color_pwd`      | color | Color of the pwd segment.      | `$fish_color_normal` |
| `hydro_color_git`      | color | Color of the git segment.      | `$fish_color_normal` |
| `hydro_color_start`    | color | Color of the start symbol.     | `$fish_color_normal` |
| `hydro_color_error`    | color | Color of the error segment.    | `$fish_color_error`  |
| `hydro_color_prompt`   | color | Color of the prompt symbol.    | `$fish_color_normal` |
| `hydro_color_duration` | color | Color of the duration section. | `$fish_color_normal` |
| `hydro_color_venv`     | color | Color of the venv segment.     | `$fish_color_normal` |

### Flags

| Variable          | Type    | Description                                  | Default |
| ----------------- | ------- | -------------------------------------------- | ------- |
| `hydro_fetch`     | boolean | Fetch git remote in the background.          | `false` |
| `hydro_multiline` | boolean | Display prompt character on a separate line. | `false` |

### Misc

| Variable                       | Type    | Description                                                                                                              | Default   |
| ------------------------------ | ------- | ------------------------------------------------------------------------------------------------------------------------ | --------- |
| `fish_prompt_pwd_dir_length`   | numeric | The number of characters to display when path shortening. Set it to `0` to display only the topmost (current) directory. | `1`       |
| `hydro_ignored_git_paths`      | strings | Space separated list of paths where no git info should be displayed.                                                     | `""`      |
| `hydro_cmd_duration_threshold` | numeric | Minimum command duration, in milliseconds, after which command duration is displayed.                                    | `1000`    |
| `hydro_log_level`              | string  | Logging level. Set to `debug` to enable debug logs.                                                                      | `"info"`  |

## License

MIT
