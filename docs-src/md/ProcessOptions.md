---
module: [kind=tables] ProcessOptions
---

A table containing options to start a process. All values below are optional, and do have defaults.

| Name           | Type      | Default Value | Description                                                                                                                                          |
| -------------- | --------- | ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `isService`    | `boolean` | `false`       | If this is true, the process will run in the background and ignore all draw requests. It will also not get key or mouse events.                      |
| `x`            | `number`  | `2`           | The X position of the window.                                                                                                                        |
| `y`            | `number`  | `2`           | The Y position of the window.                                                                                                                        |
| `w`            | `number`  | `25`          | The width of the window.                                                                                                                             |
| `h`            | `number`  | `10`          | The height of the window.                                                                                                                            |
| `isCentered`   | `boolean` | `false`       | If this is true, the window will be centered when the process starts. This overrides the X and Y options.                                            |
| `title`        | `string`  | `"Untitled"`  | The title of the process. If the process was started using a path, the title of the process (if none is provided) will be the file name of the path. |
| `hideFrame`    | `boolean` | `false`       | If set to true, the process will render with no frame (close buttons, maxamize, etc)                                                                 |
| `minimized`    | `boolean` | `false`       | If set to true, the process will be minimized when started.                                                                                          |
| `maxamized`    | `boolean` | `false`       | If set to true, the process will be maxamized when started.                                                                                          |
| `hideMinimize` | `boolean` | `false`       | If set to true, the minimize button will be hidden in the window's titlebar.                                                                         |
| `hideMaxamize` | `boolean` | `false`       | If set to true, the maxamize button will be hidden in the window's titlebar.                                                                         |
| `env`          | `table`   | `{}`          | An enviroment to pass to the window manager. Note this will not override any existing enviroment values (e.g. wm, and CraftOS term stuffs)           |
