## Introduction

Allows players to create, manage and view waypoints in the game. A waypoint is a mark that the player can set at a specific location in the world to facilitate navigation and orientation.

This implements various functions to interact with waypoints, such as setting new waypoints, moving them, changing their color, displaying the distance to a waypoint, and more.

## Available Commands:

Player Commands:
- `/wp_set <name> <color>` — creates a waypoint at your location with a color in RRGGBB format.
- `/wp_set_coord <name> <x,y,z> <color>` — creates a waypoint at given coordinates.
- `/wp_unset <name>` — deletes a waypoint.
- `/wp_list` — lists your saved waypoints.
- `/wp_show` — displays all your waypoints in the HUD.
- `/wp_hide` — hides all waypoint HUDs.
- `/wp_show_s <name>` — displays only the HUD of the specified waypoint.
- `/wp_move <name> <x,y,z>` — moves a waypoint.
- `/wp_cc <name> <color>` — changes the color of a waypoint.
- `/wp_dis <name>` — Shows the distance to the waypoint.
- `/wp_delete_all` — Deletes all your waypoints.
- `/wp_info <name>` — Details (position, color, distance).
- `/wp_rename <old> <new>` — Renames a waypoint.
- `/wp_toggle_hud <name>` — Toggles a specific HUD.

Admin commands:
- `/wp_tp <name> [player]` — Teleports to the waypoint's position (private: `waypoints_tp`).

Guild commands:
- `/guild_create <guild_name> [member1, member2, ...]` — Creates a guild and optionally sends invitations.
- `/guild_invite <guild_name> <player>` — (Leader) invites a player.
- `/guild_accept <guild_name>` — Accept an invitation.
- `/guild_decline <guild_name>` — Decline an invitation.
- `/guild_requests` — List pending invitations for you.
- `/guild_list [guild_name]` — List the guilds you belong to, or details of the specified guild (members and waypoints).
- `/guild_leave <guild_name>` — Leave a guild.
- `/guild_remove_member <guild_name> <player>` — (Leader) Removes a member.
- `/guild_transfer <guild_name> <new_leader>` — (Leader) Transfers leadership to another member.
- `/guild_wp_set <guild_name> <wp_name> <x,y,z|here> [color]` — (leader) create guild waypoint.
- `/guild_wp_move <guild_name> <wp_name> <x,y,z>` — (leader) move guild waypoint.
- `/guild_wp_cc <guild_name> <wp_name> <color>` — (leader) change color.
- `/guild_wp_unset <guild_name> <wp_name>` — (leader) remove waypoint.
- `/guild_wp_toggle <guild_name> <wp_name|all>` — toggle guild waypoint visibility for your HUD.
- `/guild_delete <guild_name>` — (leader) delete the entire guild (and clear HUDs).

## License


* MIT License (MIT) for the code.
