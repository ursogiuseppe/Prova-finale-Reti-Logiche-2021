LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.all;

entity project_reti_logiche is
port (
i_clk : in std_logic;
i_rst : in std_logic;
i_start : in std_logic;
i_data : in std_logic_vector(7 downto 0);
o_address : out std_logic_vector(15 downto 0);
o_done : out std_logic;
o_en : out std_logic;
o_we : out std_logic;
o_data : out std_logic_vector (7 downto 0)
);
end project_reti_logiche;

architecture behavioral of project_reti_logiche is

type state_type is (start_state, req_dim_state, wait_ck1_state, read_dim_state, req_data1_state, wait_ck2_state, update_max_min_state, proc_delta_value_state, req_data2_state, wait_ck3_state, proc_temp_pixel_state, end_state , proc_log_state, proc_shift_level_state, proc_newPixel_state, set_newPixel_state);

signal current_state: state_type;

signal current_address: std_logic_vector(15 downto 0);
signal last_address : std_logic_vector(15 downto 0);
signal new_address: std_logic_vector(15 downto 0);

signal request_type: std_logic;

signal num_col : std_logic_vector(7 downto 0);
signal num_rig : std_logic_vector(7 downto 0);
signal num_pixel : std_logic_vector(15 downto 0);

signal current_pixel : std_logic_vector(7 downto 0);
signal max_pixel : std_logic_vector(7 downto 0);
signal min_pixel : std_logic_vector(7 downto 0);
signal temp_pixel : std_logic_vector(15 downto 0);
signal new_pixel_value : std_logic_vector(7 downto 0);

signal delta_value_inc : std_logic_vector(8 downto 0);
signal log : std_logic_vector(7 downto 0);
signal shift_level : std_logic_vector(7 downto 0);

begin

process(i_clk, i_rst)

begin

if(i_rst='1') then
    current_state <= start_state;

elsif(rising_edge(i_clk)) then
    case current_state is
        when start_state =>
             o_done <= '0';
             o_data <= "00000000";
             request_type <= '0';
             current_address <= "0000000000000000";
             last_address <= "0000000000000000";
             new_address <= "0000000000000000";
             num_col <= "00000000";
             num_rig <= "00000000";
             num_pixel <= "0000000000000000";
             current_pixel <= "00000000";
             temp_pixel <= "0000000000000000";
             new_pixel_value <= "00000000";
             delta_value_inc <= "000000000";
             log <= "00000000";
             shift_level <= "00000000";
             max_pixel <= "00000000";
             min_pixel <= "11111111";
            if(i_start='1') then
                o_en <= '1';          
                o_we <= '0';
                current_state <= req_dim_state;
            else
                o_en <= '0';          
                o_we <= '0';
                current_state <= start_state;
            end if;
        when req_dim_state =>
            o_en <= '1';          
            o_we <= '0';
            o_address <= current_address;
            current_state <= wait_ck1_state;
        when wait_ck1_state =>
            current_state <= read_dim_state;
        when read_dim_state =>
            if(request_type = '0') then
                num_col <= i_data;
                current_address <= std_logic_vector(UNSIGNED(current_address) + 1);
                request_type <= '1';
                current_state <= req_dim_state;
            elsif(request_type = '1') then
                num_rig <= i_data;
                if(num_col = "00000000" or i_data = "00000000") then
                    current_state <= end_state ;
                else
                    current_address <= std_logic_vector(UNSIGNED(current_address) + 1);
                    num_pixel <= std_logic_vector(UNSIGNED(num_col) * UNSIGNED(i_data));
                    last_address <= std_logic_vector((UNSIGNED(num_col) * UNSIGNED(i_data))+2);
                    current_state <= req_data1_state;
                end if;
            end if;
        when req_data1_state =>
            o_en <= '1';          
            o_we <= '0';
            if(current_address = last_address or (max_pixel="11111111" and min_pixel="00000000")) then
                current_state <= proc_delta_value_state;
            else
                o_address <= current_address;
                current_address <= std_logic_vector(UNSIGNED(current_address) + 1);
                current_state <= wait_ck2_state;
            end if;
        when wait_ck2_state =>
            current_state <= update_max_min_state;
        when update_max_min_state =>
            current_pixel <= i_data;
            if(TO_INTEGER(UNSIGNED(i_data))>TO_INTEGER(UNSIGNED(max_pixel))) then
                max_pixel <= i_data;
            end if;
            if(TO_INTEGER(UNSIGNED(i_data))<TO_INTEGER(UNSIGNED(min_pixel))) then
                min_pixel <= i_data;
            end if;
            current_state <= req_data1_state;
        when proc_delta_value_state =>
            o_en <= '0';          
            o_we <= '0';
            delta_value_inc <= std_logic_vector(UNSIGNED('0' & max_pixel) - UNSIGNED('0' & min_pixel)+1);
            current_state <= proc_log_state;
        when proc_log_state =>
            if(delta_value_inc(8) = '1') then
                log <= "00001000";
            elsif(delta_value_inc(7) = '1') then
                log <= "00000111";
            elsif(delta_value_inc(6) = '1') then
                log <= "00000110";
            elsif(delta_value_inc(5) = '1') then
                log <= "00000101";
            elsif(delta_value_inc(4) = '1') then
                log <= "00000100";
            elsif(delta_value_inc(3) = '1') then
                log <= "00000011";
            elsif(delta_value_inc(2) = '1') then
                log <= "00000010";
            elsif(delta_value_inc(1) = '1') then
                log <= "00000001";
            else
                log <= "00000000";
            end if;
            current_state <= proc_shift_level_state;
        when proc_shift_level_state =>
            shift_level <= std_logic_vector(8-UNSIGNED(log));
            current_address <= "0000000000000010";
            new_address <= last_address;
            current_state <= req_data2_state;
        when req_data2_state =>
            o_en <= '1';          
            o_we <= '0';
            if(current_address = last_address) then
                current_state <= end_state ;
            else
                o_address <= current_address;
                current_address <= std_logic_vector(UNSIGNED(current_address) + 1);
                current_state <= wait_ck3_state;
            end if;
        when wait_ck3_state =>
            current_state <= proc_temp_pixel_state;
        when proc_temp_pixel_state =>
            current_pixel <= i_data;        
            if(shift_level = "00000000") then
                temp_pixel <= std_logic_vector(UNSIGNED("00000000" & i_data) - UNSIGNED("00000000" & min_pixel));
            else
                temp_pixel <= std_logic_vector(shift_left(UNSIGNED("00000000" & i_data) - UNSIGNED("00000000" & min_pixel), TO_INTEGER(UNSIGNED(shift_level))));
            end if;
            current_state <= proc_newPixel_state;
        when proc_newPixel_state =>
            if(TO_INTEGER(UNSIGNED(temp_pixel)) > 255) then
                new_pixel_value <= "11111111";
            else
                new_pixel_value <= temp_pixel(7 downto 0);
            end if;
            current_state <= set_newPixel_state;
        when set_newPixel_state =>
            o_en <= '1';          
            o_we <= '1';
            o_address <= new_address;
            o_data <= new_pixel_value;
            new_address <= std_logic_vector(UNSIGNED(new_address) + 1);
            current_state <= req_data2_state;
        when end_state  =>
            o_en <= '0';          
            o_we <= '0';
            o_done <= '1';
            if(i_start = '0') then
                current_state <= start_state;
            else
                current_state <= end_state ;
            end if;
        end case;
end if;

end process;
end architecture;