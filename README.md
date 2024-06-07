## Introduction

Allows players to create, manage and view waypoints in the game. A waypoint is a mark that the player can set at a specific location in the world to facilitate navigation and orientation.

This implements various functions to interact with waypoints, such as setting new waypoints, moving them, changing their color, displaying the distance to a waypoint, and more.

## Available Commands:


`/wp_set <name> <color>` <br>
- Description: Set a new waypoint with a specified name and color. <br>
- Usage: /wp_set base 00FF00 <br>
- This command will create a waypoint named "base" with a green color (#00FF00).

`/wp_show` <br>
- Description: Show all waypoints in the HUD. <br>
- Usage: /wp_show <br>
- This command displays all waypoints on your screen, showing their names and positions. <br>

`/wp_hide` <br>
- Description: Hide all waypoints from the HUD. <br>
- Usage: /wp_hide <br>
- Hides all waypoints that are currently displayed on the screen. <br>

`/wp_unset <name>` <br>
- Description: Remove a specific waypoint by its name. <br>
- Usage: /wp_unset base <br>
- Removes the waypoint named "base" from your list of waypoints. <br>

`/wp_list` <br>
- Description: List all waypoints along with their details. <br>
- Usage: /wp_list <br>
- Displays a list of all waypoints with their names, colors, and positions. <br>

`/wp_show_s <name>` <br>
- Description: Show a specific waypoint in the HUD and hide others. <br>
- Usage: /wp_show_s base <br>
- Displays only the waypoint named "base" on the HUD, hiding all other waypoints. <br>

`/wp_set_coord <name> <x,y,z> <color>` <br>
- Description: Set a waypoint at specific coordinates with a specified color. <br>
- Usage: /wp_set_coord home 100,50,200 FF0000 <br>
- Creates a waypoint named "home" at coordinates (100, 50, 200) with a red color (#FF0000). <br>

`/wp_move <name> <x,y,z>` <br>
- Description: Move a waypoint to a new position. <br>
- Usage: /wp_move base 150,60,180 <br>
- Moves the waypoint named "base" to the coordinates (150, 60, 180). <br>

`/wp_cc <name> <color>` <br>
- Description: Change the color of an existing waypoint. <br>
- Usage: /wp_cc base 0000FF <br>
- Changes the color of the waypoint "base" to blue (#0000FF). <br>

`/wp_dis <name>` <br>
- Description: Show the distance to a specific waypoint. <br>
- Usage: /wp_dis base <br>
- Displays the distance from your current position to the waypoint named "base." <br>

`/wp_delete_all` <br>
- Description: Delete all waypoints of the current user. <br>
- Usage: /wp_delete_all <br>
- Deletes all waypoints associated with your player name. <br>

`/wp_info <name>` <br>
- Description: Show detailed information about a specific waypoint. <br>
- Usage: /wp_info base <br>
- Displays detailed information about the waypoint named "base," including its position, color, and distance from your current position. <br>

`/wp_rename <old_name> <new_name>` <br>
- Description: Rename an existing waypoint. <br>
- Usage: /wp_rename base outpost <br>
- Renames the waypoint from "base" to "outpost." <br>

`/wp_toggle_hud <name>` <br>
- Description: Toggle the HUD display for a specific waypoint. <br>
- Usage: /wp_toggle_hud base <br>
- Toggles the visibility of the HUD display for the waypoint named "base." <br>

## License

* MIT License (MIT) for the code.