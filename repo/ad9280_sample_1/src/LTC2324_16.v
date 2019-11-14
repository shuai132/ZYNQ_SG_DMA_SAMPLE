//
// 本驱动实现110MHz时钟下 2Msps最高采样率
// 可以通过调整时钟周期自适应采样率
// 110MHz 对应 2Msps
// 33MHz  对应 600Ksps
//
// 110MHz时钟下:
// 1个时钟约9.1ns (1000/110 = 9.0909090909091)
// 2M的采样率 整个采样周期内包含的时钟数为: (1 / 2) / (1 / 110) = 55
//
// 注: 以下计算均在110MHz时钟的前提下
//
module LTC2324_16(
    input           clk,
    input           rst_n,

    // 芯片管脚信号
    output reg      CNV,
    output wire     SCK,
    input           CLKOUT,
    input           SDO1,
    input           SDO2,
    input           SDO3,
    input           SDO4,

    // 控制
    input           sample_en,      // 开启采样

    // 完成一次采集和读取
    output reg          valid,      // 1:可读 0:无效
    output reg[15:0]    ch1,
    output reg[15:0]    ch2,
    output reg[15:0]    ch3,
    output reg[15:0]    ch4
);

// 使用SCK还是CLKOUT作为数据移位时钟
parameter       USE_SCK_SHIFT_DATA  = 1'b1;

// 状态
reg[2:0]        state;
localparam      S_IDLE              = 3'd0;
localparam      S_TCNVH             = 3'd1;
localparam      S_TCONV             = 3'd2;
localparam      S_TSCK              = 3'd3;
localparam      S_DELAY             = 3'd4;

// 注: 以下计算均在110MHz时钟的前提下(时序要求见手册第5页)
reg[1:0]        tcnvh_clk_cnt;      // =30ns    30/(1000/110) = 3.3个周期
localparam      tcnvh_clk_all       = 2'd3;     // 4-1

reg[4:0]        tconv_clk_cnt;      // =220ns   220/(1000/110) = 24.2个周期
localparam      tconv_clk_all       = 5'd24;    // 25-1

reg[3:0]        tsck_clk_cnt;       // =9.1ns   1个周期共16个
localparam      tsck_clk_all        = 4'd15;    // 16-1

reg[3:0]        tdelay_clk_cnt;     // 总周期 - 已用周期: (500/(1000/110)) - (4+25+16) = 10个周期
localparam      tdelay_clk_all      = 4'd9;     // 10-1

always@(posedge clk or negedge rst_n)
begin
    if (rst_n == 1'b0)
    begin
        state <= S_IDLE;

        tcnvh_clk_cnt  <= 1'b0;
        tconv_clk_cnt  <= 1'b0;
        tsck_clk_cnt   <= 1'b0;
        tdelay_clk_cnt <= 1'b0;
    end
    else
    case(state)
        S_IDLE:
        begin
            if (sample_en)
                state <= S_TCNVH;
            else
                state <= S_IDLE;
        end
        S_TCNVH:
        begin
            if (tcnvh_clk_cnt == tcnvh_clk_all)
            begin
                tcnvh_clk_cnt <= 2'd0;
                state <= S_TCONV;
            end
            else
                tcnvh_clk_cnt <= tcnvh_clk_cnt + 1'b1;
        end
        S_TCONV:
        begin
            if (tconv_clk_cnt == tconv_clk_all)
            begin
                tconv_clk_cnt <= 5'd0;
                state <= S_TSCK;
            end
            else
                tconv_clk_cnt <= tconv_clk_cnt + 1'b1;
        end
        S_TSCK:
        begin
            if (tsck_clk_cnt == tsck_clk_all)
            begin
                tsck_clk_cnt <= 4'd0;
                state <= S_DELAY;
            end
            else
                tsck_clk_cnt <= tsck_clk_cnt + 1'b1;
        end
        S_DELAY:
        begin
            if (tdelay_clk_cnt == tdelay_clk_all)
            begin
                tdelay_clk_cnt <= 4'd0;
                if (sample_en)
                begin
                    state <= S_TCNVH;
                end
                else
                    state <= S_IDLE;
            end
            else
                tdelay_clk_cnt <= tdelay_clk_cnt + 1'b1;
        end
        default:
            state <= S_IDLE;
    endcase
end

always@(*)
begin
    if (state == S_TCNVH && sample_en)
        CNV = 1'b1;
    else
        CNV = 1'b0;
end

assign SCK = state == S_TSCK ? clk : 1'b0;

wire   DATA_SHIFT_CLK;
assign DATA_SHIFT_CLK = USE_SCK_SHIFT_DATA ? SCK : CLKOUT;

always@(posedge DATA_SHIFT_CLK or posedge CNV or negedge rst_n)
begin
    if (CNV == 1'b1 || rst_n == 1'b0)
    begin
        ch1 <= 1'b0;
        ch2 <= 1'b0;
        ch3 <= 1'b0;
        ch4 <= 1'b0;
    end
    else if (tsck_clk_cnt < tsck_clk_all)
    begin
        ch1 <= (ch1 << 1'b1) + 1;
        ch2 <= (ch2 << 1'b1) + 2;
        ch3 <= (ch3 << 1'b1) + 3;
        ch4 <= (ch4 << 1'b1) + SDO4;
    end
end

always@(*)
begin
    if (state == S_DELAY && sample_en)
        valid = 1'b1;
    else
        valid = 1'b0;
end

endmodule
