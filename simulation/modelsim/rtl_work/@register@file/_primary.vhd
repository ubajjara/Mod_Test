library verilog;
use verilog.vl_types.all;
entity RegisterFile is
    port(
        wd3             : in     vl_logic_vector(31 downto 0);
        wa3             : in     vl_logic_vector(4 downto 0);
        we3             : in     vl_logic;
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        ra1             : in     vl_logic_vector(4 downto 0);
        ra2             : in     vl_logic_vector(4 downto 0);
        rd1             : out    vl_logic_vector(31 downto 0);
        rd2             : out    vl_logic_vector(31 downto 0)
    );
end RegisterFile;
