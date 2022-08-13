---
module: [kind=misc] Window Manager Events
---

Documentation for events that may be passed from the window manager.

<table class="definition-list">
  <tr>
    <th class="definition-name"><a href="wm_minimized_changed">wm_minimized_changed</a></th>
    <td>Fires when a process is (un)minimized.</td>
  </tr>
  <tr>
    <th class="definition-name"><a href="wm_maxamized_changed">wm_maxamized_changed</a></th>
    <td>Fires when a process is (un)minimized.</td>
  </tr>
  <tr>
    <th class="definition-name"><a href="wm_focus_gained">wm_focus_gained</a></th>
    <td>Fires when a process is (un)maxamized.</td>
  </tr>
  <tr>
    <th class="definition-name"><a href="wm_focus_lost">wm_focus_lost</a></th>
    <td>Fires when a process loses focus.</td>
  </tr>
  <tr>
    <th class="definition-name"><a href="wm_native_resized">wm_native_resized</a></th>
    <td>Fires when the native window of the window manager is resized.</td>
  </tr>
</table>

<dl class="definition">
  <dt>
    <a name="wm_minimized_changed" href="#wm_minimized_changed"> </a>
    <span class="definition-name">wm_minimized_changed</span>
  </dt>
  <dd>
    <p>Fires when a process is (un)minimized.</p>
    <h3>Parameters</h3>
    <ol class="return-list">
      <li> boolean Whether or not the process is minimized</li>
    </ol>
  </dd>

  <dt>
    <a name="wm_maxamized_changed" href="#wm_maxamized_changed"> </a>
    <span class="definition-name">wm_maxamized_changed</span>
  </dt>
  <dd>
    <p>Fires when a process is (un)maxamized.</p>
    <h3>Parameters</h3>
    <ol class="return-list">
      <li> boolean Whether or not the process is maxamized</li>
    </ol>
  </dd>

  <dt>
    <a name="wm_focus_gained" href="#wm_focus_gained"> </a>
    <span class="definition-name">wm_focus_gained</span>
  </dt>
  <dd>
    <p>Fires when a process gains focus.</p>
  </dd>

  <dt>
    <a name="wm_focus_lost" href="#wm_focus_lost"> </a>
    <span class="definition-name">wm_focus_lost</span>
  </dt>
  <dd>
    <p>Fires when a process loses focus.</p>
  </dd>

  <dt>
    <a name="wm_native_resized" href="#wm_native_resized"> </a>
    <span class="definition-name">wm_native_resized</span>
  </dt>
  <dd>
    <p>Fires when the native window of the window manager is resized. term_resize is not used to keep compatability.</p>
    <ol class="return-list">
      <li> number The new width</li>
      <li> number The new height</li>
    </ol>
  </dd>
</dl>
