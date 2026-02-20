module addr::enums {
    use aptos_framework::event;

    // Simple enum with no fields.
    enum Color has copy, drop, store {
        Red,
        Blue,
        Green,
    }

    // Enum with named fields.
    enum Shape has copy, drop, store {
        Circle { radius: u64 },
        Rectangle { width: u64, height: u64 },
    }

    // Enum with enum fields (nested enums).
    enum DrawCommand has copy, drop, store {
        Fill { shape: Shape, color: Color },
        Stroke { shape: Shape, color: Color, thickness: u64 },
        Clear,
    }

    // Regular struct with enum fields.
    struct Canvas has copy, drop, store {
        background: Color,
        active_command: DrawCommand,
    }

    // Event with an enum field.
    #[event]
    struct DrawEvent has copy, drop, store {
        command: DrawCommand,
        canvas: Canvas,
    }

    public entry fun draw_circle(radius: u64) {
        let shape = Shape::Circle { radius };
        let command = DrawCommand::Fill { shape, color: Color::Blue };
        let canvas = Canvas {
            background: Color::Red,
            active_command: command,
        };
        event::emit(DrawEvent { command, canvas });
    }

    public entry fun draw_rectangle(width: u64, height: u64) {
        let shape = Shape::Rectangle { width, height };
        let command = DrawCommand::Stroke {
            shape,
            color: Color::Green,
            thickness: 2,
        };
        let canvas = Canvas {
            background: Color::Blue,
            active_command: command,
        };
        event::emit(DrawEvent { command, canvas });
    }

    fun perimeter(shape: &Shape): u64 {
        match (shape) {
            Shape::Circle { radius } => *radius * 6,
            Shape::Rectangle { width, height } => 2 * (*width + *height),
        }
    }

    fun is_clear(cmd: &DrawCommand): bool {
        cmd is DrawCommand::Clear
    }
}
