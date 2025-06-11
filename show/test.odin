package show

import "core:fmt"
import rl "vendor:raylib"
Vector2i :: [2]int
GRID_WIDTH :: 20
MAX_SNAKE_LENGTH :: GRID_WIDTH * GRID_WIDTH
snake_length: int
game_over: bool
food_pos: Vector2i

timer_check :: proc(
	tick_timer: f32,
	snake: ^[MAX_SNAKE_LENGTH]Vector2i,
	move_direction: Vector2i,
	TICK_RATE: f32,
	eat_sound, crash_sound: rl.Sound,
) -> f32 {
	tick_timer := tick_timer

	if tick_timer <= 0 {
		next_part_pos := snake[0]
		snake[0] += move_direction
		head_pos := snake[0]

		if head_pos.x <= 0 ||
		   head_pos.y <= 0 ||
		   head_pos.x >= GRID_WIDTH ||
		   head_pos.y >= GRID_WIDTH {
			game_over = true
			rl.PlaySound(crash_sound)
		}


		for i in 1 ..< snake_length {
			cur_pos := snake[i]

			if cur_pos == head_pos {
				game_over = true
				rl.PlaySound(crash_sound)
			}

			snake[i] = next_part_pos
			next_part_pos = cur_pos
		}

		if head_pos == food_pos {
			snake_length += 1
			snake[snake_length - 1] = next_part_pos
			place_food(snake^)
			rl.PlaySound(eat_sound)
		}

		tick_timer = TICK_RATE + tick_timer
	}
	return tick_timer
}

place_food :: proc(snake: [MAX_SNAKE_LENGTH]Vector2i) {
	occupied: [GRID_WIDTH][GRID_WIDTH]bool

	for i in 0 ..< snake_length {
		occupied[snake[i].x][snake[i].y] = true
	}

	free_cells := make([dynamic]Vector2i, context.temp_allocator)

	for x in 0 ..< GRID_WIDTH {
		for y in 0 ..< GRID_WIDTH {
			if !occupied[x][y] {
				append(&free_cells, Vector2i{x, y})
			}
		}
	}

	if len(free_cells) > 0 {
		random_cell_index := rl.GetRandomValue(0, i32(len(free_cells) - 1))
		food_pos = free_cells[random_cell_index]
	}
}
