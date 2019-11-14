module ad9280_sample(
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
reg[2:0]            write_cnt;
localparam          write_num   = 3'd7;

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
            end
            else
            begin
                // fifo_din <= adc_data;
                fifo_din   <= write_cnt;    // 模拟
                fifo_wr_en <= 1'b1;

                if (write_cnt == write_num)
                begin
                    write_cnt  <= 1'b0;
                    sample_cnt <= sample_cnt + 32'd1;
                end
                else
                    write_cnt  <= write_cnt + 1'b1;
            end
        end
        default:
            state <= S_IDLE;
    endcase
end

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
