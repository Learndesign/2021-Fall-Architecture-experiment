`include "mycpu.h"

module if_stage(
    input                          clk            ,
    input                          reset          ,
    //allwoin
    input                          ds_allowin     ,
    //brbus
    input  [`BR_BUS_WD       -1:0] br_bus         ,
    //to ds
    output                         fs_to_ds_valid ,
    output [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus   ,
    // inst sram interface
    output        inst_sram_en   ,    // req
    output [ 3:0] inst_sram_wen  ,
    output [ 1:0] inst_sram_size ,  //lab10
    output reg[31:0] inst_sram_addr ,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata,
    input         inst_sram_addr_ok,  //lan10
    input         inst_sram_data_ok,  //lab10
    // from wb
    input  [`WS_TO_FS_BUS_WD - 1 :0]  ws_to_fs_bus,
    input         ws_block       ,
    // from csr
    input  [31:0] ex_entry       ,
    input  [31:0] ertn_entry

);
// PRE_FS
wire        pre_fs_req;
wire        pre_fs_ready_go;
wire        to_fs_valid;

// FS
reg         fs_valid;
wire        fs_ready_go;
wire        fs_allowin;
wire        fs_cancel;


wire ws_ex;
wire ws_ertn;
//lab14
wire [31:0] refetch_pc;
wire        ws_refetch;


assign {refetch_pc,  //34:3
        ws_refetch,  //2:2
        ws_ertn,     //1:1
        ws_ex        //0:0
        } = ws_to_fs_bus;
        
wire ds_refetch;
reg refetch_block;
// 当流水线上有重取标志时有效，用于阻塞pre_if级。
always @(posedge clk) begin
    if(reset) begin 
        refetch_block <= 1'b0;
    end
    else if(ds_refetch)
        refetch_block <= 1'b1;
    else if(ws_refetch)
        refetch_block <= 1'b0;
end

reg         ws_ex_hold;
reg         ws_ertn_hold;
reg         ws_refetch_hold;
reg         br_cancel_hold;
reg [31:0]  br_target_hold;
wire        br_stall;
wire        br_taken_cancel;
wire [31:0] br_target;
assign {ds_refetch,br_stall, br_taken_cancel,br_target} = br_bus;

reg not_cancel;
always @(posedge clk) begin
    if(reset)begin
        not_cancel <= 1'b0;
    end
    else if(pre_fs_req && (br_taken_cancel || fs_cancel))begin
        not_cancel <= 1'b1;
    end
    else if(pre_fs_ready_go)
        not_cancel <= 1'b0;
end
wire real_not_cancel;
assign real_not_cancel = pre_fs_req && (br_taken_cancel || fs_cancel);

//lab14
always @(posedge clk) begin
    if(reset) begin 
        br_cancel_hold <= 1'b0;
        ws_ex_hold <= 1'b0;
        ws_ertn_hold <= 1'b0;
        ws_refetch_hold <= 1'b0;
    end
    else if(pre_fs_ready_go && !not_cancel && !real_not_cancel) begin
        br_cancel_hold <= 1'b0;
        ws_ex_hold <= 1'b0;
        ws_ertn_hold <= 1'b0;
        ws_refetch_hold <= 1'b0;
    end
    else begin 
        if(br_taken_cancel)
            br_cancel_hold <= 1'b1;
        if(ws_ex)
            ws_ex_hold <= 1'b1;
        if(ws_ertn)
            ws_ertn_hold <=1'b1;
        if(ws_refetch)
            ws_refetch_hold<=1'b1;
    end

    if(reset)
        br_target_hold <= 32'b0;
    else if(br_taken_cancel)
        br_target_hold <= br_target;
    
end


wire        fs_pc_exce;              //取指异常信号
wire [31:0] fs_inst;
reg  [31:0] fs_pc;
assign fs_to_ds_bus = {
                       fs_pc_exce,      //64:64
                       fs_inst   ,      //63:32   
                       fs_pc            //31:0
                       };

// 31~0: 保存的指令 
// 32  : fs向ds传递的值是否在fs_inst_buf中
reg [32:0]fs_inst_buf;
reg fs_inst_buf_discard;


// 最简单的实现：仅当 IF 级 allowin 为 1 时pre-IF 级才可以对外发出地址请求
assign pre_fs_req      = fs_allowin && !br_stall;
assign pre_fs_ready_go = pre_fs_req && inst_sram_addr_ok && !(ds_refetch || refetch_block);
assign to_fs_valid     =  pre_fs_ready_go;

// pre-IF stage
wire [31:0] seq_pc;
wire [31:0] nextpc;
assign seq_pc       = fs_pc + 3'h4;
assign nextpc       =   (ws_ex | ws_ex_hold) ?  ex_entry :       
                                    (ws_ertn | ws_ertn_hold) ? ertn_entry :
                                        (ws_refetch | ws_refetch_hold) ? refetch_pc+4 :  //lab14
                                            (br_taken_cancel) ? br_target :
                                                  (br_cancel_hold) ? br_target_hold :                      
                                        seq_pc;
reg first;
always @(posedge clk) begin
    if(reset)begin
        first <= 1'b0;
    end
    else if(pre_fs_req && !first)begin
        first <= 1'b1;
    end
    else if(pre_fs_ready_go)begin
        first <= 1'b0;
    end
end
always @(posedge clk) begin
    if(reset)begin
        inst_sram_addr <= 32'h1c000000;
    end
    else if(pre_fs_req && !first)begin
        inst_sram_addr <= nextpc;
    end
    else 
        inst_sram_addr <= inst_sram_addr;
end

assign fs_cancel      = ws_block;
assign fs_ready_go    = (inst_sram_data_ok || fs_inst_buf[32]) && !fs_inst_buf_discard && !(ds_refetch || refetch_block);
assign fs_allowin     = !fs_valid || fs_ready_go && ds_allowin;
assign fs_to_ds_valid =  fs_valid && fs_ready_go;


always @(posedge clk) begin
    if (reset || fs_cancel || br_taken_cancel || not_cancel || ds_refetch || ws_refetch) begin
        fs_valid <= 1'b0;
    end
    else if (fs_allowin) begin
        fs_valid <= to_fs_valid;
    end

    if (reset) begin
        fs_pc <= 32'h1bfffffc;  //trick: to make nextpc be 0x1c000000 during reset 
    end
    else if (to_fs_valid && fs_allowin) begin
        fs_pc <= inst_sram_addr;
    end
end

assign inst_sram_en    = pre_fs_req;
assign inst_sram_wen   = 4'h0;
// assign inst_sram_addr  = nextpc;
assign inst_sram_wdata = 32'b0;
assign inst_sram_size  = 2'b10;

assign fs_inst         = (fs_inst_buf[32]) ? fs_inst_buf : inst_sram_rdata;

assign fs_pc_exce = |fs_pc[1:0]; // pc[1:0] != 0 ADEE;


// 用 fs_inst_buf 保存 IF 级取回的指令
always @(posedge clk) begin
    if(reset || fs_cancel) begin
        fs_inst_buf[32] <= 1'b0;
    end
    else if(inst_sram_data_ok && fs_valid && !ds_allowin)
        fs_inst_buf[32] <= 1'b1;
    else if(ds_allowin && fs_ready_go)
        fs_inst_buf[32] <= 1'b0;

    if(inst_sram_data_ok)
        fs_inst_buf[31:0] <= inst_sram_rdata;
end
// 标记是否舍弃下一个读来的数据
always @(posedge clk) begin
    if(reset || inst_sram_data_ok)
        fs_inst_buf_discard <= 1'b0;
    else if(pre_fs_req && (fs_cancel || br_taken_cancel || ws_refetch)|| !fs_allowin && !fs_ready_go && (fs_cancel || br_taken_cancel))
        fs_inst_buf_discard <= 1'b1;
end

endmodule
