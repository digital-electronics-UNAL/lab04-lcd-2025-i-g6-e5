module LCD1602_controller #(
    parameter NUM_COMMANDS = 4,
    NUM_DATA_ALL = 32,
    NUM_DATA_PERLINE = 16,
    DATA_BITS = 8,
    COUNT_MAX = 800000
)(
    input clk,
    input reset,
    input [DATA_BITS-1:0] din_data,  // Entrada dinámica
    output reg rs,
    output reg rw,
    output enable,
    output reg [DATA_BITS-1:0] data
);

// Definición de estados
localparam IDLE              = 3'b000;
localparam STORE_DATA        = 3'b001;
localparam CONFIG_CMD1       = 3'b010;
localparam WR_STATIC_TEXT_1L = 3'b011;
localparam CONFIG_CMD2       = 3'b100;
localparam WR_STATIC_TEXT_2L = 3'b101;

reg [2:0] fsm_state;
reg [2:0] next_state;
reg clk_16ms;

// Comandos LCD
localparam CLEAR_DISPLAY              = 8'h01;
localparam SHIFT_CURSOR_RIGHT         = 8'h06;
localparam DISPON_CURSOROFF           = 8'h0C;
localparam LINES2_MATRIX5x8_MODE8bit  = 8'h38;
localparam START_2LINE                = 8'hC0;

// Contadores
reg [$clog2(COUNT_MAX)-1:0] clk_counter;
reg [$clog2(NUM_COMMANDS):0] command_counter;
reg [$clog2(NUM_DATA_PERLINE):0] data_counter;
reg [$clog2(NUM_DATA_ALL):0] input_counter;

// Memorias internas
reg [DATA_BITS-1:0] static_data_mem [0:NUM_DATA_ALL-1];
reg [DATA_BITS-1:0] config_mem [0:NUM_COMMANDS-1];

// Clock lento
always @(posedge clk) begin
    if (clk_counter == COUNT_MAX-1) begin
        clk_16ms <= ~clk_16ms;
        clk_counter <= 0;
    end else begin
        clk_counter <= clk_counter + 1;
    end
end

// Inicialización
initial begin
    fsm_state <= IDLE;
    rs <= 0;
    rw <= 0;
    data <= 0;
    clk_16ms <= 0;
    clk_counter <= 0;
    input_counter <= 0;

    config_mem[0] <= LINES2_MATRIX5x8_MODE8bit;
    config_mem[1] <= SHIFT_CURSOR_RIGHT;
    config_mem[2] <= DISPON_CURSOROFF;
    config_mem[3] <= CLEAR_DISPLAY;
end

// FSM: cambio de estado
always @(posedge clk_16ms) begin
    if (!reset)
        fsm_state <= IDLE;
    else
        fsm_state <= next_state;
end

// FSM: lógica de transición
always @(*) begin
    case (fsm_state)
        IDLE: begin
            next_state = STORE_DATA;
        end

        STORE_DATA: begin
            next_state = (input_counter == NUM_DATA_ALL) ? CONFIG_CMD1 : STORE_DATA;
        end

        CONFIG_CMD1: begin
            next_state = (command_counter == NUM_COMMANDS) ? WR_STATIC_TEXT_1L : CONFIG_CMD1;
        end

        WR_STATIC_TEXT_1L: begin
            next_state = (data_counter == NUM_DATA_PERLINE) ? CONFIG_CMD2 : WR_STATIC_TEXT_1L;
        end

        CONFIG_CMD2: begin
            next_state = WR_STATIC_TEXT_2L;
        end

        WR_STATIC_TEXT_2L: begin
            next_state = (data_counter == NUM_DATA_PERLINE) ? IDLE : WR_STATIC_TEXT_2L;
        end

        default: next_state = IDLE;
    endcase
end

// FSM: lógica de salida y control
always @(posedge clk_16ms) begin
    if (!reset) begin
        command_counter <= 0;
        data_counter <= 0;
        input_counter <= 0;
        data <= 0;
        rs <= 0;
        last_sw_data <= 0;  // <<<<< Inicializa el dato anterior
    end else begin
        case (fsm_state)
            IDLE: begin
                command_counter <= 0;
                data_counter <= 0;
                input_counter <= 0;
                rs <= 0;
                data <= 0;
                last_sw_data <= 0;  // <<<<< Re-inicializa también aquí
            end

            STORE_DATA: begin
                if ((din_data != last_sw_data) && (input_counter < NUM_DATA_ALL)) begin
                    static_data_mem[input_counter] <= din_data;
                    input_counter <= input_counter + 1;
                    last_sw_data <= din_data;  // <<<<< Guarda el dato actual como "último"
                end
            end

            CONFIG_CMD1: begin
                rs <= 0;
                data <= config_mem[command_counter];
                command_counter <= command_counter + 1;
            end

            WR_STATIC_TEXT_1L: begin
                rs <= 1;
                data <= static_data_mem[data_counter];
                data_counter <= data_counter + 1;
            end

            CONFIG_CMD2: begin
                rs <= 0;
                data <= START_2LINE;
                data_counter <= 0;
            end

            WR_STATIC_TEXT_2L: begin
                rs <= 1;
                data <= static_data_mem[NUM_DATA_PERLINE + data_counter];
                data_counter <= data_counter + 1;
            end
        endcase
    end
end


assign enable = clk_16ms;

endmodule
