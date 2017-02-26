# Rece
An electron based extensible level editor for the future!

---

### Installing and Running Rece

To run 'Rece' you will need `NodeJS` (and by extension `npm`), aswell as a global electron installation:

`npm install electron -g`

Then clone the repo:

`git clone https://github.com/retroverse/Rece.git`

Navigate to the repository then install all required node modules (this may take a little while)

`npm install`

And then you can run Rece with

`electron .`

---

### Using Rece

First you will need a project directory in this format:

```
Project
├───project.cson
├───instances/
├───levels/
└───tiles/
```

There is an `example_project` in the rece repository.
Then use the
**Load Project** button and select your project.
Now you should see your projects tile on the left.

Now you can load a level, use the **Open Level** button and select a `.lvl` file (there are several in the `example_project/levels` directory).

---

### Parts of Rece
#### The Topbar
Houses the IO functionality.

#### The navbar
Houses the Tools, Layers, Tiles and Instances.

#### The editor
This is where you place tiles and instances, it's view can be panned with `RMB + Drag` and zoomed with the `MOUSE WHEEL`.

#### Tools
There are four tools;
  - __The place Tool__ (`D`) - Places tiles and instances.
  - __The remove Tool__ (`E`) - Removes tiles and instances.
  - __The Select Tool__ (`S`) - Selects a group of tiles and instances, hold `CTRL` while selecting to fill the region instead of selecting.
  - __The Picker Tool__ (hold `ALT`) - Selects a tile or instance to select it in the tile/instance view.

#### Layers
Layers split the level into parts, They can be selected by being clicked on, you can add a layer by clicking on the `+`,  removed by clicking on the `RUBBISH BIN` and renamed by being selected while already selected.

#### Extra Functionality
  - Press the arrow keys to move the selected tiles/instances.
  - Press `G` to toggle the grid.
  - Press `DEL` to delete selected tiles/instances.
