---
module: [kind=misc] TriggerMethod
---

A table containing a method to trigger a context menu.

| Name          | Valid Values / Type      | Description                                                                                                                                                              |
| ------------- | ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| type          | regionClick / rightClick | How the context menu will be triggered. regionClick defines a region that must be clicked, whilst rightClick is anywhere, as long as the right mouse button was pressed. |
| buttonTrigger | number                   | The button that must be pressed to trigger this context menu. This is only required for the regionClick type.                                                            |
| minX          | number                   | The min X for triggering the context menu. Only required for regionClick.                                                                                                |
| maxX          | number                   | The max X for triggering the context menu. Only required for regionClick.                                                                                                |
| minY          | number                   | The min Y for triggering the context menu. Only required for regionClick.                                                                                                |
| maxY          | number                   | The max Y for triggering the context menu. Only required for regionClick.                                                                                                |
