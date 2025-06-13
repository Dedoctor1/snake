package snake// "package <name>" muss bei jeder Datei angegeben werden, sonst kompiliert er nicht

/*
Folgende Bibliotheken (oder Verzeichnisse) werden importiert, um Funktionen und Prozeduren anzuwenden
*/
import "core:fmt"
import "core:math"
import rl "vendor:raylib"

/*
Die Variable kann (global) mit den Beispielen Variablename : (Datentyp) = wert oder Variablename : Datentyp überschrieben werden,
aber bei den konstanten Variable (Beispiele: Variablename :: Wert oder Variablename : Datentyp: Wert) kann sie (auch global) nicht überschrieben werden.
*/

WINDOW_SIZE :: 720
GRID_WIDTH :: 20
CELL_SIZE :: 16
CANVAS_SIZE :: GRID_WIDTH * CELL_SIZE
Vector2i :: [2]int
TICK_RATE :: 0.13
MAX_SNAKE_LENGTH :: GRID_WIDTH * GRID_WIDTH

snake: [MAX_SNAKE_LENGTH]Vector2i
snake_length: int
tick_timer: f32 = TICK_RATE
move_direction: Vector2i
game_over: bool
food_pos: Vector2i

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT}) // Einrichtung der Konfiguration, um vertikale Syncronisation zu aktivieren
	rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Snake") // Initialisierung des Fensters
	rl.SetWindowState({.WINDOW_RESIZABLE}) // Man Kann mit der linken Maustaste das Fenster größer oder kleiner ziehen
	rl.InitAudioDevice() // Schaltet das Audiogerät ein

	restart() // Die restart Prozedur setzt die Schlange wieder in die ursprüngliche Position zurück

	//Texturen werden geladen, damit die Bilder in der Benutzeroberfläche angezeigt werden
	food_sprite := rl.LoadTexture("./pictures/food.png")
	head_sprite := rl.LoadTexture("./pictures/head.png")
	body_sprite := rl.LoadTexture("./pictures/body.png")
	tail_sprite := rl.LoadTexture("./pictures/tail.png")

	//Sounds werden geladen, damit die im Hintergrund abgespielt werden
	eat_sound := rl.LoadSound("./sounds/eat.wav")
	crash_sound := rl.LoadSound("./sounds/crash.wav")

	// Dieser Main Loop läuft so lange,
	// bis man auf das Kreuz des Fensters getippt oder auf die ESC-Taste gedrückt hat
	for !rl.WindowShouldClose() {

		if rl.IsKeyDown(.W) {
			move_direction = {0, -1}
		}
		if rl.IsKeyDown(.S) {
			move_direction = {0, 1}
		}

		if rl.IsKeyDown(.A) {
			move_direction = {-1, 0}
		}
		if rl.IsKeyDown(.D) {
			move_direction = {1, 0}
		}

		if game_over {
			if rl.IsKeyPressed(.ENTER) {
				restart()
			}

		} else {
			/*
			Die Variable ist dasselbe wie tick_timer = tick_timer - rl.GetFrameTime() 
			//NOTE: Die Funktion GetFrameTime() gibt die Zeit in Sekunden für das letzte gezeichnete Bild zurück
			*/
			tick_timer -= rl.GetFrameTime()
		}

		// NOTE: Die Prozedur Playsound() spielt den Sound ab.
		if tick_timer <= 0 {
			next_part_pos := snake[0]
			snake[0] += move_direction
			head_pos := snake[0]

			// Wenn die Schlange gegen die Wand stößt, ist das Spiel vorbei
			if head_pos.x <= 0 ||
			   head_pos.y <= 0 ||
			   head_pos.x >= GRID_WIDTH ||
			   head_pos.y >= GRID_WIDTH {
				game_over = true
				rl.PlaySound(crash_sound)
			}

			// Jeder Körper bewegt sich ein Schritt
			for i in 1 ..< snake_length {
				cur_pos := snake[i]

				// Die Schlange kann sich selbst stoßen und schon ist das Spiel ebenfalls vorbei
				if cur_pos == head_pos {
					game_over = true
					rl.PlaySound(crash_sound)
				}

				snake[i] = next_part_pos
				next_part_pos = cur_pos
			}

			// Jedes Mal wird sie größer, wenn sie ein ganzen Apfel gegessen hat.
			// NOTE: Die Prozedur place_food plaziert das Essen zufällig.
			if head_pos == food_pos {
				snake_length += 1
				snake[snake_length - 1] = next_part_pos
				place_food()
				rl.PlaySound(eat_sound)
			}

			tick_timer = TICK_RATE + tick_timer
		}

		rl.BeginDrawing() // Anfang der Zeichnung
		rl.ClearBackground({50, 53, 83, 255}) // Das Fenster wird mit der Hintergrundfarbe gefüllt

		// Kamara zoomt 320 mm näher ran.
		camera := rl.Camera2D {
			zoom = f32(WINDOW_SIZE) / CANVAS_SIZE,
		}

		rl.BeginMode2D(camera) // Beginn der 2D Modus

		// Zeichnung der 2D Textur als Vector2
		rl.DrawTextureV(food_sprite, {f32(food_pos.x), f32(food_pos.y)} * CELL_SIZE, rl.WHITE)

		for i in 0 ..< snake_length {
			part_sprite := body_sprite
			direction: Vector2i

			if i == 0 {
				part_sprite = head_sprite
				direction = snake[i] - snake[i + 1]
			} else if i == snake_length - 1 {
				part_sprite = tail_sprite
				direction = snake[i - 1] - snake[i]
			} else {
				direction = snake[i - 1] - snake[i]
			}

			/*
			atan steht für Arcustangens und den nutzt man, um Tangens (also Gegenkathete / Ankathete) aufzulösen.
			DEG_PER_RAD (Degrees per Radians) übersetzt ins Deutsche Grad pro Radiant (zu tief ins Mathematik).
			Nachdem man den Arcustangens berechnet hat, multipliziert man zunächst mit den Grad pro Radiant.
			//NOTE: Die Schlange soll sich um eine Richtung drehen und bewegen können.
			*/
			rotation := math.atan2(f32(direction.y), f32(direction.x)) * math.DEG_PER_RAD

			source := rl.Rectangle{0, 0, f32(part_sprite.width), f32(part_sprite.height)}

			destination := rl.Rectangle {
				f32(snake[i].x) * CELL_SIZE + 0.5 * CELL_SIZE,
				f32(snake[i].y) * CELL_SIZE + 0.5 * CELL_SIZE,
				CELL_SIZE,
				CELL_SIZE,
			}

			rl.DrawTexturePro(
				part_sprite,
				source,
				destination,
				{CELL_SIZE, CELL_SIZE} * 0.5,
				rotation,
				rl.WHITE,
			)
		}

		// Nach dem Ende des Spiels wird der High score angezeigt.
		if game_over {
			high_score := snake_length - 3
			high_score_str := fmt.ctprintf("High Score: %v", high_score)
			rl.DrawText("Game Over!", 4, 4, 25, rl.RED)
			rl.DrawText("Press Enter to play again", 4, 30, 15, rl.BLACK)
			rl.DrawText(high_score_str, 4, 50, 15, rl.GRAY)
		}

		// Für jedes Essen gibt es ein Punkt
		score := snake_length - 3
		score_str := fmt.ctprintf("Score: %v", score)
		rl.DrawText(score_str, 4, CANVAS_SIZE - 14, 10, rl.GRAY)

		rl.EndMode2D() // Ende der 2D Modus
		rl.EndDrawing() // Ende der Zeichnung

		free_all(context.temp_allocator) // gibt alle temporären Speicher an das Betriebssystem zurück
	}

	/*
	Die Texturen mit Bilder und Soundeffekte werden entladen
	*/

	rl.UnloadTexture(head_sprite)
	rl.UnloadTexture(food_sprite)
	rl.UnloadTexture(body_sprite)
	rl.UnloadTexture(tail_sprite)

	rl.UnloadSound(eat_sound)
	rl.UnloadSound(crash_sound)

	rl.CloseAudioDevice() // schaltet das Audiogerät aus
	rl.CloseWindow() // das Fenster schließen
}

place_food :: proc() {
	occupied: [GRID_WIDTH][GRID_WIDTH]bool

	for i in 0 ..< snake_length {
		occupied[snake[i].x][snake[i].y] = true
	}

	free_cells := make([dynamic]Vector2i, context.temp_allocator) // Der Speicher wird durch die make Funktion dynamisch temporär zugewiesen.

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

restart :: proc() {
	start_head_pos: Vector2i = {GRID_WIDTH / 2, GRID_WIDTH / 2}
	snake[0] = start_head_pos
	snake[1] = start_head_pos - {0, 1}
	snake[2] = start_head_pos - {0, 2}
	snake_length = 3
	move_direction = {0, 1}
	game_over = false
	place_food()
}
