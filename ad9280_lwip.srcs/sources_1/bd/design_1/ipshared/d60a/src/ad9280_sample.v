module AXI_DMA_LTC2324_16(
    input               adc_clk,
    input               adc_rst_n,

    // ADC
    output              adc_CNV,
    output              adc_SCK,
    input               adc_CLKOUT,
    input               adc_SDO1,
    input               adc_SDO2,
    input               adc_SDO3,
    input               adc_SDO4,

    // CTRL
    input[31:0]         sample_len,
    input               sample_start,
    output reg          st_clr,

    // AXIS
    output[7:0]         DMA_AXIS_tdata,
    output[0:0]         DMA_AXIS_tkeep,
    output              DMA_AXIS_tlast,
    input               DMA_AXIS_tready,
    output              DMA_AXIS_tvalid,
    input[0:0]          DMA_RST_N,
    input               DMA_CLK
);

reg[31:0]           sample_cnt;
reg[31:0]           wait_cnt;
reg                 fifo_wr_en;
reg[7:0]            fifo_din;
wire[9:0]           fifo_rd_data_count;
wire                fifo_rd_en;
reg                 fifo_rd_en_d0;
wire                fifo_empty;

reg[31:0]           dma_cnt;

reg                 tvalid_en;

reg[2:0]            state;
localparam          S_IDLE      = 0;
localparam          S_SAMPLE    = 1;

// 这个axis ip核的数据位宽是8位，但是我们传输一次4个通道ADC数据每个16位，总共64位。分8次传送。
reg[2+3:0]          write_cnt;
localparam          write_num   = 4'd8;

// ADC
wire                adc_valid;
wire[15:0]          adc_ch1;
wire[15:0]          adc_ch2;
wire[15:0]          adc_ch3;
wire[15:0]          adc_ch4;
wire[63:0]          adc_data;
assign              adc_data = {adc_ch1, adc_ch2, adc_ch3, adc_ch4};

reg                 adc_valid_flag;

always@(posedge adc_clk or negedge adc_rst_n)
begin
    if(adc_rst_n == 1'b0)
    begin
        state      <= S_IDLE;
        wait_cnt   <= 32'd0;
        sample_cnt <= 32'd0;
        fifo_din   <= 8'd0;
        fifo_wr_en <= 1'b0;
        st_clr     <= 1'b0;
        write_cnt  <= 1'b0;
    end
    else
    case(state)
        S_IDLE:
        begin
            if (sample_start)
            begin
                st_clr <= 1'b1;
                state  <= S_SAMPLE;
            end
        end
        S_SAMPLE:
        begin
            if(sample_cnt == sample_len)
            begin
                sample_cnt <= 32'd0;
                fifo_wr_en <= 1'b0;
                state      <= S_IDLE;
                st_clr     <= 1'b0;
                fifo_din   <= 1'b0;
                write_cnt  <= 1'b0;
                adc_valid_flag <= 1'b0;
            end
            else
            begin
                if (adc_valid)
                    adc_valid_flag <= 1'b1;

                // adc_valid高电平时进行读取adc数据
                // 已知持续时间大于8个时钟 可分八次传送
                // adc_valid_flag是为了把valid信号延长至少读取完8个字节
                if (adc_valid || adc_valid_flag) begin
                    fifo_wr_en <= 1'b1;

                    // arm是小端模式 这里也把高位字节放到前面 方便解析
                    fifo_din <= adc_data >> (write_cnt << 3);
                    // fifo_din <= adc_data >> (64 - 8 - (write_cnt << 3));

                    if (write_cnt == write_num)
                    begin
                        write_cnt  <= 1'b0;
                        fifo_wr_en <= 1'b0;
                        sample_cnt <= sample_cnt + 32'd1;
                        adc_valid_flag <= 1'b0;
                    end
                    else
                        write_cnt  <= write_cnt + 1'b1;
                end
            end
        end
        default:
            state <= S_IDLE;
    endcase
end

LTC2324_16 LTC2324_16_inst
(
    .clk        (adc_clk),
    .rst_n      (adc_rst_n),

    .CNV        (adc_CNV),
    .SCK        (adc_SCK),
    .CLKOUT     (adc_CLKOUT),
    .SDO1       (adc_SDO1),
    .SDO2       (adc_SDO2),
    .SDO3       (adc_SDO3),
    .SDO4       (adc_SDO4),

    .sample_en  ((state == S_SAMPLE) && (sample_cnt != sample_len)),

    .valid      (adc_valid),
    .ch1        (adc_ch1),
    .ch2        (adc_ch2),
    .ch3        (adc_ch3),
    .ch4        (adc_ch4)
);

afifo afifo_inst
(
    .rst              (~DMA_RST_N     ),
    .wr_clk           (adc_clk        ),
    .rd_clk           (DMA_CLK        ),
    .din              (fifo_din       ),
    .wr_en            (fifo_wr_en     ),
    .rd_en            (fifo_rd_en     ),
    .dout             (DMA_AXIS_tdata ),
    .full             (               ),
    .empty            (fifo_empty     ),
    .rd_data_count    (fifo_rd_data_count),
    .wr_data_count    (               )
);

assign fifo_rd_en = DMA_AXIS_tready && ~fifo_empty;

always@(posedge DMA_CLK or negedge DMA_RST_N)
begin
    if(DMA_RST_N == 1'b0)
        fifo_rd_en_d0 <= 1'b0;
    else
        fifo_rd_en_d0 <= fifo_rd_en;
end

always@(posedge DMA_CLK or negedge DMA_RST_N)
begin
    if(DMA_RST_N == 1'b0)
        tvalid_en <= 1'b0;
    else if (fifo_rd_en_d0 & ~DMA_AXIS_tready)
        tvalid_en <= 1'b1;
    else if (DMA_AXIS_tready)
        tvalid_en <= 1'b0;
end

always@(posedge DMA_CLK or negedge DMA_RST_N)
begin
    if(DMA_RST_N == 1'b0)
        dma_cnt <= 32'd0;
    else if (DMA_AXIS_tvalid & ~DMA_AXIS_tlast)
        dma_cnt <= dma_cnt + 1'b1;
    else if (DMA_AXIS_tvalid & DMA_AXIS_tlast)
        dma_cnt <= 32'd0;
end

assign DMA_AXIS_tkeep  = 1'b1;
assign DMA_AXIS_tvalid = DMA_AXIS_tready & (tvalid_en | fifo_rd_en_d0);
assign DMA_AXIS_tlast  = DMA_AXIS_tvalid & (dma_cnt == sample_len - 1);

endmodule
