module tlb
#(
parameter TLBNUM = 16
)
(
input clk,
// search port 0 (for fetch)
input [ 18:0] s0_vppn,
input s0_va_bit12,
input [ 9:0] s0_asid,
output s0_found,
output [$clog2(TLBNUM)-1:0] s0_index,
output [ 19:0] s0_ppn,
output [ 5:0] s0_ps,
output [ 1:0] s0_plv,
output [ 1:0] s0_mat,
output s0_d,
output s0_v,
// search port 1 (for load/store)
input [ 18:0] s1_vppn,
input s1_va_bit12,
input [ 9:0] s1_asid,
output s1_found,
output [$clog2(TLBNUM)-1:0] s1_index,
output [ 19:0] s1_ppn,
output [ 5:0] s1_ps,
output [ 1:0] s1_plv,
output [ 1:0] s1_mat,
output s1_d,
output s1_v,
// invtlb opcode
input [ 4:0] invtlb_op,
input invtlb_valid,
// write port
input we, //w(rite) e(nable)
input [$clog2(TLBNUM)-1:0] w_index,
input w_e,
input [ 18:0] w_vppn,
input [ 5:0] w_ps,
input [ 9:0] w_asid,
input w_g,
input [ 19:0] w_ppn0,
input [ 1:0] w_plv0,
input [ 1:0] w_mat0,
input w_d0,
input w_v0,
input [ 19:0] w_ppn1,
input [ 1:0] w_plv1,
input [ 1:0] w_mat1,
input w_d1,
input w_v1,
// read port
input [$clog2(TLBNUM)-1:0] r_index,
output r_e,
output [ 18:0] r_vppn,
output [ 5:0] r_ps,
output [ 9:0] r_asid,
output r_g,
output [ 19:0] r_ppn0,
output [ 1:0] r_plv0,
output [ 1:0] r_mat0,
output r_d0,
output r_v0,
output [ 19:0] r_ppn1,
output [ 1:0] r_plv1,
output [ 1:0] r_mat1,
output r_d1,
output r_v1
);
reg [TLBNUM-1:0] tlb_e;
reg [TLBNUM-1:0] tlb_ps4MB; //pagesize 1:4MB, 0:4KB
reg [ 18:0] tlb_vppn [TLBNUM-1:0];
reg [ 9:0] tlb_asid [TLBNUM-1:0];
reg tlb_g [TLBNUM-1:0];
reg [ 19:0] tlb_ppn0 [TLBNUM-1:0];
reg [ 1:0] tlb_plv0 [TLBNUM-1:0];
reg [ 1:0] tlb_mat0 [TLBNUM-1:0];
reg tlb_d0 [TLBNUM-1:0];
reg tlb_v0 [TLBNUM-1:0];
reg [ 19:0] tlb_ppn1 [TLBNUM-1:0];
reg [ 1:0] tlb_plv1 [TLBNUM-1:0];
reg [ 1:0] tlb_mat1 [TLBNUM-1:0];
reg tlb_d1 [TLBNUM-1:0];
reg tlb_v1 [TLBNUM-1:0];


wire s0_choose_bit;
wire s1_choose_bit;

assign s0_choose_bit = (s0_ps == 6'd22)? s0_vppn[9] : s0_va_bit12;
assign s1_choose_bit = (s1_ps == 6'd22)? s1_vppn[9] : s1_va_bit12;

//写
always @(posedge clk) begin
    if (we) begin
       tlb_ps4MB [w_index] <= w_ps == 6'd22;
       tlb_vppn  [w_index] <= w_vppn;
       tlb_asid  [w_index] <= w_asid;
       tlb_g     [w_index] <= w_g;
       tlb_ppn0  [w_index] <= w_ppn0;
       tlb_plv0  [w_index] <= w_plv0;
       tlb_mat0  [w_index] <= w_mat0;
       tlb_d0    [w_index] <= w_d0;
       tlb_v0    [w_index] <= w_v0;
       tlb_ppn1  [w_index] <= w_ppn1;
       tlb_plv1  [w_index] <= w_plv1;
       tlb_mat1  [w_index] <= w_mat1;
       tlb_d1    [w_index] <= w_d1;
       tlb_v1    [w_index] <= w_v1;
    end
end

//读
assign r_e    = tlb_e     [r_index];
assign r_vppn = tlb_vppn  [r_index];
assign r_ps   = tlb_ps4MB [r_index]? 6'd22 : 6'd12;  
assign r_asid = tlb_asid  [r_index]; 
assign r_g    = tlb_g     [r_index];  
assign r_ppn0 = tlb_ppn0  [r_index];
assign r_plv0 = tlb_plv0  [r_index];
assign r_mat0 = tlb_mat0  [r_index];
assign r_d0   = tlb_d0    [r_index];
assign r_v0   = tlb_v0    [r_index];
assign r_ppn1 = tlb_ppn1  [r_index];
assign r_plv1 = tlb_plv1  [r_index];
assign r_mat1 = tlb_mat1  [r_index];
assign r_d1   = tlb_d1    [r_index];
assign r_v1   = tlb_v1    [r_index]; 

//查找
wire [TLBNUM-1 : 0] match0;
genvar i0;
generate for (i0=0; i0<TLBNUM; i0=i0+1) begin : gen_for_match0
          assign match0[ i0] = (s0_vppn[18:10]==tlb_vppn[ i0][18:10]) 
                && (tlb_ps4MB[ i0] || s0_vppn[9:0]==tlb_vppn[ i0][9:0])
                && ((s0_asid==tlb_asid[ i0]) || tlb_g[ i0]);
end endgenerate

wire [TLBNUM-1 : 0] match1;
genvar i1;
generate for (i1=0; i1<TLBNUM; i1=i1+1) begin : gen_for_match1
          assign match1[ i1] = (s1_vppn[18:10]==tlb_vppn[ i1][18:10]) 
                && (tlb_ps4MB[ i1] || s1_vppn[9:0]==tlb_vppn[ i1][9:0])
                && ((s1_asid==tlb_asid[ i1]) || tlb_g[ i1]);
end endgenerate

wire [3:0] cond[TLBNUM-1:0];
genvar i4;
generate for (i4 = 0; i4 < TLBNUM ; i4=i4+1) begin
    assign cond[i4][0] = tlb_g[i4] == 1'b1;
    assign cond[i4][1] = tlb_g[i4] == 1'b0;
    assign cond[i4][2] = s1_asid == tlb_asid[i4];
    assign cond[i4][3] = s1_vppn == tlb_vppn[i4] && !((s1_ps == 6'd22) ^ tlb_ps4MB[i4]);
end
endgenerate

genvar i3;
generate for(i3=0; i3<TLBNUM;i3=i3+1)
    always @(posedge clk) begin
        if (we && w_index == i3)
            tlb_e[w_index] <= w_e;
        else if((invtlb_op == 0 || 
                invtlb_op == 1 || 
                invtlb_op == 2 &&  cond[i3][0] ||
                invtlb_op == 3 &&  cond[i3][1] ||
                invtlb_op == 4 &&  cond[i3][1] && cond[i3][2] ||
                invtlb_op == 5 &&  cond[i3][1] && cond[i3][2] && cond[i3][3] ||
                invtlb_op == 6 && (cond[i3][0] || cond[i3][2]) && cond[i3][3] ) && invtlb_valid)
                tlb_e[i3] <= 1'b0;
    end
endgenerate

assign s0_found = |match0;
assign s0_index = {4{match0[ 0]}} & 4'd0  | 
                  {4{match0[ 1]}} & 4'd1  | 
                  {4{match0[ 2]}} & 4'd2  | 
                  {4{match0[ 3]}} & 4'd3  | 
                  {4{match0[ 4]}} & 4'd4  | 
                  {4{match0[ 5]}} & 4'd5  | 
                  {4{match0[ 6]}} & 4'd6  | 
                  {4{match0[ 7]}} & 4'd7  | 
                  {4{match0[ 8]}} & 4'd8  | 
                  {4{match0[ 9]}} & 4'd9  | 
                  {4{match0[10]}} & 4'd10 | 
                  {4{match0[11]}} & 4'd11 | 
                  {4{match0[12]}} & 4'd12 | 
                  {4{match0[13]}} & 4'd13 | 
                  {4{match0[14]}} & 4'd14 | 
                  {4{match0[15]}} & 4'd15 ;

assign s0_ppn = (s0_choose_bit)? tlb_ppn1[s0_index] : tlb_ppn0[s0_index];
assign s0_ps  = tlb_ps4MB [s0_index]? 6'd22 : 6'd12; 
assign s0_mat = (s0_choose_bit)? tlb_mat1[s0_index] : tlb_mat0[s0_index];
assign s0_d   = (s0_choose_bit)? tlb_d1  [s0_index] : tlb_d0  [s0_index];
assign s0_plv = (s0_choose_bit)? tlb_plv1[s0_index] : tlb_plv0[s0_index];
assign s0_v   = (s0_choose_bit)? tlb_v1  [s0_index] : tlb_v0  [s0_index];


assign s1_found = |match1;
assign s1_index = {4{match1[ 0]}} & 4'd0  | 
                  {4{match1[ 1]}} & 4'd1  | 
                  {4{match1[ 2]}} & 4'd2  | 
                  {4{match1[ 3]}} & 4'd3  | 
                  {4{match1[ 4]}} & 4'd4  | 
                  {4{match1[ 5]}} & 4'd5  | 
                  {4{match1[ 6]}} & 4'd6  | 
                  {4{match1[ 7]}} & 4'd7  | 
                  {4{match1[ 8]}} & 4'd8  | 
                  {4{match1[ 9]}} & 4'd9  | 
                  {4{match1[10]}} & 4'd10 | 
                  {4{match1[11]}} & 4'd11 | 
                  {4{match1[12]}} & 4'd12 | 
                  {4{match1[13]}} & 4'd13 | 
                  {4{match1[14]}} & 4'd14 | 
                  {4{match1[15]}} & 4'd15 ;

assign s1_ppn = (s1_choose_bit)? tlb_ppn1[s1_index] : tlb_ppn0[s1_index];
assign s1_ps  = tlb_ps4MB [s1_index]? 6'd22 : 6'd12;
assign s1_mat = (s1_choose_bit)? tlb_mat1[s1_index] : tlb_mat0[s1_index];
assign s1_d   = (s1_choose_bit)? tlb_d1  [s1_index] : tlb_d0  [s1_index];
assign s1_plv = (s1_choose_bit)? tlb_plv1[s1_index] : tlb_plv0[s1_index];
assign s1_v   = (s1_choose_bit)? tlb_v1  [s1_index] : tlb_v0  [s1_index];



endmodule