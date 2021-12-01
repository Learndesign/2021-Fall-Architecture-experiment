`ifndef MYCPU_H
    `define MYCPU_H

    `define BR_BUS_WD 35
    `define FS_TO_DS_BUS_WD 65
    `define DS_TO_ES_BUS_WD 296
    `define ES_TO_MS_BUS_WD 169
    `define MS_TO_WS_BUS_WD 194
    `define ES_TO_DS_BUS_WD 55
    `define MS_TO_DS_BUS_WD 55
    `define MS_TO_ES_BUS_WD 16
    `define WS_TO_RF_BUS_WD 54
    `define WS_TO_FS_BUS_WD 35

    // CSR
    `define CSR_CRMD 14'h0
    `define CSR_PRMD 14'h1   
    `define CSR_ECFG 14'h4   
    `define CSR_ESTAT 14'h5   
    `define CSR_ERA 14'h6   
    `define CSR_BADV 14'h7   
    `define CSR_EENTRY 14'hc   
    `define CSR_TLBIDX 14'h10
    `define CSR_TLBEHI 14'h11
    `define CSR_TLBELO0 14'h12
    `define CSR_TLBELO1 14'h13
    `define CSR_ASID 14'h18
    `define CSR_SAVE0 14'h30   
    `define CSR_SAVE1 14'h31  
    `define CSR_SAVE2 14'h32  
    `define CSR_SAVE3 14'h33  
    `define CSR_TID 14'h40  
    `define CSR_TCFG 14'h41  
    `define CSR_TAVL 14'h42  
    `define CSR_TICLR 14'h44 
    `define CSR_DMW0 14'h180 
    `define CSR_DMW1 14'h181

    `define ECODE_INT 14'h0 //中断
    `define ECODE_ADE 14'h8
    `define ECODE_ALE 14'h9 //地址非对齐
    `define ECODE_SYS 14'hb
    `define ECODE_BRK 14'hc //断点
    `define ECODE_INE 14'hd //指令不存在
    `define ECODE_INVTLB 14'hd
    
    `define ESUBCODE_ADEF 14'h0 //取地址错例外
    `define ESUBCODE_ADEM 14'h1 //访存指令地址错例外


`endif