library verilog;
use verilog.vl_types.all;
entity Mod_Teste is
    port(
        CLOCK_27        : in     vl_logic;
        CLOCK_50        : in     vl_logic;
        KEY             : in     vl_logic_vector(3 downto 0);
        SW              : in     vl_logic_vector(17 downto 0);
        HEX0            : out    vl_logic_vector(0 to 6);
        HEX1            : out    vl_logic_vector(0 to 6);
        HEX2            : out    vl_logic_vector(0 to 6);
        HEX3            : out    vl_logic_vector(0 to 6);
        HEX4            : out    vl_logic_vector(0 to 6);
        HEX5            : out    vl_logic_vector(0 to 6);
        HEX6            : out    vl_logic_vector(0 to 6);
        HEX7            : out    vl_logic_vector(0 to 6);
        LEDG            : out    vl_logic_vector(8 downto 0);
        LEDR            : out    vl_logic_vector(17 downto 0);
        UART_TXD        : out    vl_logic;
        UART_RXD        : in     vl_logic;
        LCD_DATA        : inout  vl_logic_vector(7 downto 0);
        LCD_ON          : out    vl_logic;
        LCD_BLON        : out    vl_logic;
        LCD_RW          : out    vl_logic;
        LCD_EN          : out    vl_logic;
        LCD_RS          : out    vl_logic;
        GPIO_0          : inout  vl_logic_vector(35 downto 0);
        GPIO_1          : inout  vl_logic_vector(35 downto 0)
    );
end Mod_Teste;
