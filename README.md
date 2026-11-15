# BounceBack
BounceBack is a 2D pixel-art platformer where you launch a slime from one surface to the next. Stick to a wall, aim your next shot before you slide too far, and use the ceiling to get past spikes and cannon fire.
Controls
Input	Action
Left-click while attached to a surface	Launch toward the cursor.
Hold the left mouse button, drag, and release	Pull back to aim and launch in the opposite direction. A longer pull gives a stronger shot.
Dotted preview	Shows the launch trajectory while you aim.


# Gameplay
- Stick to floors, slide down walls, and hang from ceilings for a short time.
- Cross grassy platforms, explore the Castle of Despair, and descend into the Lava Depths.
- Touch switches to toggle platforms and reach each stage’s exit.
- Dodge spikes and cannon shots. Surviving a hit sends you back to the stage checkpoint. A spike you survive can become a safe landing spot. The third hit restarts the stage.
# Run locally
1. Install Godot 4.7.2.
2. In Godot’s Project Manager, click Import and choose this repository’s project.godot.
3. Open the project and press F5 to launch the game. To test one stage, open its scene and press F6.
# Export for itch.io
1. Install the export templates for your Godot version and add a Web preset under Project → Export. Use the Compatibility renderer.
2. Export to an empty folder with the entry file named index.html. ZIP the exported files together, with index.html at the ZIP root.
3. On itch.io, set Kind of Game to HTML, upload the ZIP, and mark it as playable in the browser.
