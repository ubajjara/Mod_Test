library verilog;
use verilog.vl_types.all;
entity Mod_Teste_vlg_check_tst is
    port(
        GPIO_0          : in     vl_logic_vector(35 downto 0);
        GPIO_1          : in     vl_logic_vector(35 downto 0);
        HEX0            : in     vl_logic_vector(0 to 6);
        HEX1            : in     vl_logic_vector(0 to 6);
        HEX2            : in     vl_logic_vector(0 to 6);
        HEX3            : in     vl_logic_vector(0 to 6);
        HEX4            : in     vl_logic_vector(0 to 6);
        HEX5            : in     vl_logic_vector(0 to 6);
        HEX6            : in     vl_logic_vector(0 to 6);
        HEX7            : in     vl_logic_vector(0 to 6);
        LCD_BLON        : in     vl_logic;
        LCD_DATA        : in     vl_logic_vector(7 downto 0);
        LCD_EN          : in     vl_logic;
        LCD_ON          : in     vl_logic;
        LCD_RS          : in     vl_logic;
        LCD_RW          : in     vl_logic;
        LEDG            : in     vl_logic_vector(8 downto 0);
        LEDR            : in     vl_logic_vector(17 downto 0);
        UART_TXD        : in     vl_logic;
        sampler_rx      : in     vl_logic
    );
end Mod_Teste_vlg_check_tst;
