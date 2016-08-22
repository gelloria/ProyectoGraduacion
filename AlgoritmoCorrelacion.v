`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

//Diseño Realizado para señales de 128 muestras y un OSF de 8


module Correlacion(Bitstream,Clk,Read,Reset,Data_Out,Flag);

    input Bitstream;
    input Clk;
    input Read;
    input Reset;
    
    output [10:0] Data_Out;
    output Flag;
    
    wire [1023:0] Patron;
    wire [1023:0] Muestra;
    wire [1023:0] Multiplicacion;
    wire [511:0] DatosSuma;
    wire[10:0] Correlacion;
    
    wire Shift_PR,Shift_SR;
    wire EPC,EFC;
    wire S1, S2, S3, S4, S5;
    wire FlagP;
    
    //S1 Se;al que habilita la escritura en el registro de muestra
    //S2: Se;al que activa la bandera
    //S3: FCE se;al que avisa cuando se desactiva la bandera
    //S4: Se;al que se activa antes de activar la bandera
    //S5: Se;al que indica cuando se ha escrito el octavo bit
    
    Signal_Register RPatron(Clk, Reset, Shift_PR, Bitstream, Patron);
    Signal_Register RMuestra(Clk, Reset, Shift_SR, Bitstream, Muestra);
    
    assign FCE = S3;
    assign Flag=FlagP;
    //assign Flag=FlagP&S5;
    //Maquina_Estados Control(Clk,Reset,Read,ESR,FCE,Shift_PR,Shift_SR,EPC,EFC);
    Maquina_Estados Control(Clk,Reset,Read,ESR,1'd1,Shift_PR,Shift_SR,EPC,EFC);
    
    BitsCounter CBits(Clk, Reset, Shift_SR, S5);
    Pattern_Counter ContadorPatron(Clk,Reset,EPC,S1);
    FlagCounter ContadorBandera(Clk, Reset|S5, EFC, S2,S3, S4);
    
    FF_JK FFA(Clk, S1, Reset, ESR);
    FF_JK FFB(Clk, S2, S3|Reset, FlagP);
    
    Multiplicador Multiplcador(Patron,Muestra,Multiplicacion);
    
    DecosSuma Deco(Multiplicacion,DatosSuma);
    
    Sumatoria Sum(DatosSuma, Correlacion);
    
    RegistroCorrelacion Resultado(Clk, Reset, S5, Correlacion, Data_Out);
    
endmodule


////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
//module Signal_Register#(parameter NM=10, parameter OSF=8)(Clk, Reset, Shift, Data_In, Data_Out);
module Signal_Register(Clk, Reset, Shift, Data_In, Data_Out);

//--Input Ports--    
    input Clk;
    input Reset;
    input Shift;
    input Data_In;
        
//--Output Ports--
//output wire [(NM*OSF)-1:0] Data_Out;
//output wire [1023:0] Data_Out;
    output reg [1023:0] Data_Out;
    
//--Internal Variables--
//reg [1023:0] Temp;
//reg [(NM*OSF)-1:0] Temp;


    always @ (posedge Clk)
        if(Reset)
        //Temp <= 0;
            Data_Out=0;
        else if(Shift)
        //Temp <= {Data_In, Temp[1023:1]};
        //Temp <= {Data_In, Temp[(NM*OSF)-1:1]};
            Data_Out={Data_In,Data_Out[1023:1]};
        else
            Data_Out=Data_Out;
//assign Data_Out = Temp;
    
    
endmodule




////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

module Maquina_Estados(Clk,Reset,Read,ESR,FCE,Shift_PR,Shift_SR,EPC,EFC);
    
    //--Input Ports-- 
    input Clk;
    input Reset;
    input Read;
    input ESR;
    input FCE;
    
    //--Output Ports-- 
    output reg Shift_PR;
    output reg Shift_SR;
    output reg EPC;
    output reg EFC;
    
    //registros de estado
    reg [2:0] PRE,FUT;
    parameter T0=3'b000, T1=3'b001,T2=3'b010,T3=3'b011, T4=3'b100, T5=3'b101,T6=3'b110,T7=3'b111;
    
    //registro de transicion de estado
    always @(negedge Clk or posedge Reset)
        if(Reset)
            PRE=0;
        else
            PRE=FUT;
                
    //red de estado futuro
    always  @(PRE or Read or ESR or FCE)
        case (PRE)
            T0:if (Read)
                    FUT=T1;
                else
                    FUT=T0;
            T1: FUT=T2;
            T2:if(Read)
                    FUT=T2;
                else
                    FUT=T3;
            T3: if (ESR)
                    FUT=T4;
                else
                    FUT=T0;
            T4: if (Read)
                    FUT=T5;
                else
                    FUT=T4;
            T5: FUT=T6;
            T6: if (FCE)
                    FUT=T7;
                else
                    FUT=T6;
            T7: if (Read)
                    FUT=T7;
                else
                    FUT=T4;
        endcase
            
    //asignacion de salidas
    always @ (PRE)
        case (PRE)
        
            T0:begin
                    Shift_PR=1'b0;
                    Shift_SR=1'b0;
                    EPC=1'b0;
                    EFC=1'b0;                    
                end
            T1:begin
                    Shift_PR=1'b1;
                    Shift_SR=1'b0;
                    EPC=1'b1;
                    EFC=1'b0;                    
                end
            T2:begin
                    Shift_PR=1'b0;
                    Shift_SR=1'b0;
                    EPC=1'b0;
                    EFC=1'b0;  
                end
            T3:begin
                    Shift_PR=1'b0;
                    Shift_SR=1'b0;
                    EPC=1'b0;
                    EFC=1'b0;
                end
            T4:begin
                    Shift_PR=1'b0;
                    Shift_SR=1'b0;
                    EPC=1'b0;
                    EFC=1'b1;
                end
            T5:begin
                    Shift_PR=1'b0;
                    Shift_SR=1'b1;
                    EPC=1'b0;
                    EFC=1'b1;
                end
            T6:begin
                    Shift_PR=1'b0;
                    Shift_SR=1'b0;
                    EPC=1'b0;
                    EFC=1'b1;
                end
            T7:begin
                    Shift_PR=1'b0;
                    Shift_SR=1'b0;
                    EPC=1'b0;
                    EFC=1'b1;
                end
                   
        endcase
    
    
endmodule


////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

module BitsCounter(Clk, Reset, EN, S);
    input Clk, Reset;
    input EN;
    
    output S;
    
    reg[3:0] Cuenta;
    
    always @ (posedge Clk)
        if(Reset||Cuenta==4'd8)
            Cuenta=4'd0;
        else if(EN)
            Cuenta=Cuenta+4'd1;
        else
            Cuenta=Cuenta;
            
    assign S=(Cuenta==4'd8);
    
endmodule

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

module Pattern_Counter(Clk,Reset,EN,S1);
    
    input Clk;
    input Reset;
    input EN;
    
    output S1;
    
    //--Internal Variables--
    reg [10:0] Cuenta;
        
    always @(posedge Clk)
        
    if (Reset)
        Cuenta=11'd0;
    else if (EN)
        Cuenta=Cuenta+11'd1;
    else
        Cuenta=Cuenta;
        
    //assign S1=(Cuenta==11'd128);
    
    assign S1=(Cuenta==11'd24);  

endmodule

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

module FlagCounter(Clk, Reset, EN, S1,S2,S3);

    //--Inputs--
    input Clk;
    input EN;
    input Reset;

    //--Outputs--
    output S1,S2,S3;

    //--Internal Variables--
    reg [3:0] Cuenta;
	
	always @(posedge Clk)
	   if (Reset)
	       Cuenta=4'd0;    
	   else if ((EN)&(Cuenta!=4'd5))
	       Cuenta=Cuenta+4'd1;
	   else
	       Cuenta=Cuenta;
	
	assign S1=(Cuenta==4'd2);   //Activa bandera
    assign S2=(Cuenta==4'd4); //Desactiva bandera
    assign S3=(Cuenta==4'd1); //Habilida registro con valor de correlacion


endmodule

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

module FF_JK(Clk, J, K, Q);
    //--Input Ports--  
    input Clk;
    input J;
    input K;
    
    //--Output Ports--  
    output reg Q;
    
    //--Internal Variables--
    wire D;
        
    assign D=((J&~Q) | (~K&Q));
        
    always @ (posedge Clk)
        Q=D;


endmodule


////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

module Multiplicador(A,B,C);
    input [1023:0] A;
    input [1023:0] B;
    output [1023:0] C;
    
    assign C= ~(A^B);
    //assign C = A|B;
    //assign C=A-^B;
endmodule

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////


module DecosSuma(Input,Output);
    input [1023:0] Input;
    output [511:0] Output;
    
    Deco_Sum DecoS1(Input[7:0],Output[3:0]);
    Deco_Sum DecoS2(Input[15:8],Output[7:4]);
    Deco_Sum DecoS3(Input[23:16],Output[11:8]);
    Deco_Sum DecoS4(Input[31:24],Output[15:12]);
    Deco_Sum DecoS5(Input[39:32],Output[19:16]);
    Deco_Sum DecoS6(Input[47:40],Output[23:20]);
    Deco_Sum DecoS7(Input[55:48],Output[27:24]);
    Deco_Sum DecoS8(Input[63:56],Output[31:28]);
    Deco_Sum DecoS9(Input[71:64],Output[35:32]);
    Deco_Sum DecoS10(Input[79:72],Output[39:36]);
    Deco_Sum DecoS11(Input[87:80],Output[43:40]);
    Deco_Sum DecoS12(Input[95:88],Output[47:44]);
    Deco_Sum DecoS13(Input[103:96],Output[51:48]);
    Deco_Sum DecoS14(Input[111:104],Output[55:52]);
    Deco_Sum DecoS15(Input[119:112],Output[59:56]);
    Deco_Sum DecoS16(Input[127:120],Output[63:60]);
    Deco_Sum DecoS17(Input[135:128],Output[67:64]);
    Deco_Sum DecoS18(Input[143:136],Output[71:68]);
    Deco_Sum DecoS19(Input[151:144],Output[75:72]);
    Deco_Sum DecoS20(Input[159:152],Output[79:76]);
    Deco_Sum DecoS21(Input[167:160],Output[83:80]);
    Deco_Sum DecoS22(Input[175:168],Output[87:84]);
    Deco_Sum DecoS23(Input[183:176],Output[91:88]);
    Deco_Sum DecoS24(Input[191:184],Output[95:92]);
    Deco_Sum DecoS25(Input[199:192],Output[99:96]);
    Deco_Sum DecoS26(Input[207:200],Output[103:100]);
    Deco_Sum DecoS27(Input[215:208],Output[107:104]);
    Deco_Sum DecoS28(Input[223:216],Output[111:108]);
    Deco_Sum DecoS29(Input[231:224],Output[115:112]);
    Deco_Sum DecoS30(Input[239:232],Output[119:116]);
    Deco_Sum DecoS31(Input[247:240],Output[123:120]);
    Deco_Sum DecoS32(Input[255:248],Output[127:124]);
    Deco_Sum DecoS33(Input[263:256],Output[131:128]);
    Deco_Sum DecoS34(Input[271:264],Output[135:132]);
    Deco_Sum DecoS35(Input[279:272],Output[139:136]);
    Deco_Sum DecoS36(Input[287:280],Output[143:140]);
    Deco_Sum DecoS37(Input[295:288],Output[147:144]);
    Deco_Sum DecoS38(Input[303:296],Output[151:148]);
    Deco_Sum DecoS39(Input[311:304],Output[155:152]);
    Deco_Sum DecoS40(Input[319:312],Output[159:156]);
    Deco_Sum DecoS41(Input[327:320],Output[163:160]);
    Deco_Sum DecoS42(Input[335:328],Output[167:164]);
    Deco_Sum DecoS43(Input[343:336],Output[171:168]);
    Deco_Sum DecoS44(Input[351:344],Output[175:172]);
    Deco_Sum DecoS45(Input[359:352],Output[179:176]);
    Deco_Sum DecoS46(Input[367:360],Output[183:180]);
    Deco_Sum DecoS47(Input[375:368],Output[187:184]);
    Deco_Sum DecoS48(Input[383:376],Output[191:188]);
    Deco_Sum DecoS49(Input[391:384],Output[195:192]);
    Deco_Sum DecoS50(Input[399:392],Output[199:196]);
    Deco_Sum DecoS51(Input[407:400],Output[203:200]);
    Deco_Sum DecoS52(Input[415:408],Output[207:204]);
    Deco_Sum DecoS53(Input[423:416],Output[211:208]);
    Deco_Sum DecoS54(Input[431:424],Output[215:212]);
    Deco_Sum DecoS55(Input[439:432],Output[219:216]);
    Deco_Sum DecoS56(Input[447:440],Output[223:220]);
    Deco_Sum DecoS57(Input[455:448],Output[227:224]);
    Deco_Sum DecoS58(Input[463:456],Output[231:228]);
    Deco_Sum DecoS59(Input[471:464],Output[235:232]);
    Deco_Sum DecoS60(Input[479:472],Output[239:236]);
    Deco_Sum DecoS61(Input[487:480],Output[243:240]);
    Deco_Sum DecoS62(Input[495:488],Output[247:244]);
    Deco_Sum DecoS63(Input[503:496],Output[251:248]);
    Deco_Sum DecoS64(Input[511:504],Output[255:252]);
    Deco_Sum DecoS65(Input[519:512],Output[259:256]);
    Deco_Sum DecoS66(Input[527:520],Output[263:260]);
    Deco_Sum DecoS67(Input[535:528],Output[267:264]);
    Deco_Sum DecoS68(Input[543:536],Output[271:268]);
    Deco_Sum DecoS69(Input[551:544],Output[275:272]);
    Deco_Sum DecoS70(Input[559:552],Output[279:276]);
    Deco_Sum DecoS71(Input[567:560],Output[283:280]);
    Deco_Sum DecoS72(Input[575:568],Output[287:284]);
    Deco_Sum DecoS73(Input[583:576],Output[291:288]);
    Deco_Sum DecoS74(Input[591:584],Output[295:292]);
    Deco_Sum DecoS75(Input[599:592],Output[299:296]);
    Deco_Sum DecoS76(Input[607:600],Output[303:300]);
    Deco_Sum DecoS77(Input[615:608],Output[307:304]);
    Deco_Sum DecoS78(Input[623:616],Output[311:308]);
    Deco_Sum DecoS79(Input[631:624],Output[315:312]);
    Deco_Sum DecoS80(Input[639:632],Output[319:316]);
    Deco_Sum DecoS81(Input[647:640],Output[323:320]);
    Deco_Sum DecoS82(Input[655:648],Output[327:324]);
    Deco_Sum DecoS83(Input[663:656],Output[331:328]);
    Deco_Sum DecoS84(Input[671:664],Output[335:332]);
    Deco_Sum DecoS85(Input[679:672],Output[339:336]);
    Deco_Sum DecoS86(Input[687:680],Output[343:340]);
    Deco_Sum DecoS87(Input[695:688],Output[347:344]);
    Deco_Sum DecoS88(Input[703:696],Output[351:348]);
    Deco_Sum DecoS89(Input[711:704],Output[355:352]);
    Deco_Sum DecoS90(Input[719:712],Output[359:356]);
    Deco_Sum DecoS91(Input[727:720],Output[363:360]);
    Deco_Sum DecoS92(Input[735:728],Output[367:364]);
    Deco_Sum DecoS93(Input[743:736],Output[371:368]);
    Deco_Sum DecoS94(Input[751:744],Output[375:372]);
    Deco_Sum DecoS95(Input[759:752],Output[379:376]);
    Deco_Sum DecoS96(Input[767:760],Output[383:380]);
    Deco_Sum DecoS97(Input[775:768],Output[387:384]);
    Deco_Sum DecoS98(Input[783:776],Output[391:388]);
    Deco_Sum DecoS99(Input[791:784],Output[395:392]);
    Deco_Sum DecoS100(Input[799:792],Output[399:396]);
    Deco_Sum DecoS101(Input[807:800],Output[403:400]);
    Deco_Sum DecoS102(Input[815:808],Output[407:404]);
    Deco_Sum DecoS103(Input[823:816],Output[411:408]);
    Deco_Sum DecoS104(Input[831:824],Output[415:412]);
    Deco_Sum DecoS105(Input[839:832],Output[419:416]);
    Deco_Sum DecoS106(Input[847:840],Output[423:420]);
    Deco_Sum DecoS107(Input[855:848],Output[427:424]);
    Deco_Sum DecoS108(Input[863:856],Output[431:428]);
    Deco_Sum DecoS109(Input[871:864],Output[435:432]);
    Deco_Sum DecoS110(Input[879:872],Output[439:436]);
    Deco_Sum DecoS111(Input[887:880],Output[443:440]);
    Deco_Sum DecoS112(Input[895:888],Output[447:444]);
    Deco_Sum DecoS113(Input[903:896],Output[451:448]);
    Deco_Sum DecoS114(Input[911:904],Output[455:452]);
    Deco_Sum DecoS115(Input[919:912],Output[459:456]);
    Deco_Sum DecoS116(Input[927:920],Output[463:460]);
    Deco_Sum DecoS117(Input[935:928],Output[467:464]);
    Deco_Sum DecoS118(Input[943:936],Output[471:468]);
    Deco_Sum DecoS119(Input[951:944],Output[475:472]);
    Deco_Sum DecoS120(Input[959:952],Output[479:476]);
    Deco_Sum DecoS121(Input[967:960],Output[483:480]);
    Deco_Sum DecoS122(Input[975:968],Output[487:484]);
    Deco_Sum DecoS123(Input[983:976],Output[491:488]);
    Deco_Sum DecoS124(Input[991:984],Output[495:492]);
    Deco_Sum DecoS125(Input[999:992],Output[499:496]);
    Deco_Sum DecoS126(Input[1007:1000],Output[503:500]);
    Deco_Sum DecoS127(Input[1015:1008],Output[507:504]);
    Deco_Sum DecoS128(Input[1023:1016],Output[511:508]);

endmodule


////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////


module Deco_Sum(Input, Output);
	input [7:0]Input;
	output reg[3:0]Output;
	
	
	always @ (Input)
		case(Input)
			8'd0: Output=4'd0;
            8'd1: Output=4'd1;
            8'd2: Output=4'd1;
            8'd3: Output=4'd2;
            8'd4: Output=4'd1;
            8'd5: Output=4'd2;
            8'd6: Output=4'd2;
            8'd7: Output=4'd3;
            8'd8: Output=4'd1;
            8'd9: Output=4'd2;
            8'd10: Output=4'd2;
            8'd11: Output=4'd3;
            8'd12: Output=4'd2;
            8'd13: Output=4'd3;
            8'd14: Output=4'd3;
            8'd15: Output=4'd4;
            8'd16: Output=4'd1;
            8'd17: Output=4'd2;
            8'd18: Output=4'd2;
            8'd19: Output=4'd3;
            8'd20: Output=4'd2;
            8'd21: Output=4'd3;
            8'd22: Output=4'd3;
            8'd23: Output=4'd4;
            8'd24: Output=4'd2;
            8'd25: Output=4'd3;
            8'd26: Output=4'd3;
            8'd27: Output=4'd4;
            8'd28: Output=4'd3;
            8'd29: Output=4'd4;
            8'd30: Output=4'd4;
            8'd31: Output=4'd5;
            8'd32: Output=4'd1;
            8'd33: Output=4'd2;
            8'd34: Output=4'd2;
            8'd35: Output=4'd3;
            8'd36: Output=4'd2;
            8'd37: Output=4'd3;
            8'd38: Output=4'd3;
            8'd39: Output=4'd4;
            8'd40: Output=4'd2;
            8'd41: Output=4'd3;
            8'd42: Output=4'd3;
            8'd43: Output=4'd4;
            8'd44: Output=4'd3;
            8'd45: Output=4'd4;
            8'd46: Output=4'd4;
            8'd47: Output=4'd5;
            8'd48: Output=4'd2;
            8'd49: Output=4'd3;
            8'd50: Output=4'd3;
            8'd51: Output=4'd4;
            8'd52: Output=4'd3;
            8'd53: Output=4'd4;
            8'd54: Output=4'd4;
            8'd55: Output=4'd5;
            8'd56: Output=4'd3;
            8'd57: Output=4'd4;
            8'd58: Output=4'd4;
            8'd59: Output=4'd5;
            8'd60: Output=4'd4;
            8'd61: Output=4'd5;
            8'd62: Output=4'd5;
            8'd63: Output=4'd6;
            8'd64: Output=4'd1;
            8'd65: Output=4'd2;
            8'd66: Output=4'd2;
            8'd67: Output=4'd3;
            8'd68: Output=4'd2;
            8'd69: Output=4'd3;
            8'd70: Output=4'd3;
            8'd71: Output=4'd4;
            8'd72: Output=4'd2;
            8'd73: Output=4'd3;
            8'd74: Output=4'd3;
            8'd75: Output=4'd4;
            8'd76: Output=4'd3;
            8'd77: Output=4'd4;
            8'd78: Output=4'd4;
            8'd79: Output=4'd5;
            8'd80: Output=4'd2;
            8'd81: Output=4'd3;
            8'd82: Output=4'd3;
            8'd83: Output=4'd4;
            8'd84: Output=4'd3;
            8'd85: Output=4'd4;
            8'd86: Output=4'd4;
            8'd87: Output=4'd5;
            8'd88: Output=4'd3;
            8'd89: Output=4'd4;
            8'd90: Output=4'd4;
            8'd91: Output=4'd5;
            8'd92: Output=4'd4;
            8'd93: Output=4'd5;
            8'd94: Output=4'd5;
            8'd95: Output=4'd6;
            8'd96: Output=4'd2;
            8'd97: Output=4'd3;
            8'd98: Output=4'd3;
            8'd99: Output=4'd4;
            8'd100: Output=4'd3;
            8'd101: Output=4'd4;
            8'd102: Output=4'd4;
            8'd103: Output=4'd5;
            8'd104: Output=4'd3;
            8'd105: Output=4'd4;
            8'd106: Output=4'd4;
            8'd107: Output=4'd5;
            8'd108: Output=4'd4;
            8'd109: Output=4'd5;
            8'd110: Output=4'd5;
            8'd111: Output=4'd6;
            8'd112: Output=4'd3;
            8'd113: Output=4'd4;
            8'd114: Output=4'd4;
            8'd115: Output=4'd5;
            8'd116: Output=4'd4;
            8'd117: Output=4'd5;
            8'd118: Output=4'd5;
            8'd119: Output=4'd6;
            8'd120: Output=4'd4;
            8'd121: Output=4'd5;
            8'd122: Output=4'd5;
            8'd123: Output=4'd6;
            8'd124: Output=4'd5;
            8'd125: Output=4'd6;
            8'd126: Output=4'd6;
            8'd127: Output=4'd7;
            8'd128: Output=4'd1;
            8'd129: Output=4'd2;
            8'd130: Output=4'd2;
            8'd131: Output=4'd3;
            8'd132: Output=4'd2;
            8'd133: Output=4'd3;
            8'd134: Output=4'd3;
            8'd135: Output=4'd4;
            8'd136: Output=4'd2;
            8'd137: Output=4'd3;
            8'd138: Output=4'd3;
            8'd139: Output=4'd4;
            8'd140: Output=4'd3;
            8'd141: Output=4'd4;
            8'd142: Output=4'd4;
            8'd143: Output=4'd5;
            8'd144: Output=4'd2;
            8'd145: Output=4'd3;
            8'd146: Output=4'd3;
            8'd147: Output=4'd4;
            8'd148: Output=4'd3;
            8'd149: Output=4'd4;
            8'd150: Output=4'd4;
            8'd151: Output=4'd5;
            8'd152: Output=4'd3;
            8'd153: Output=4'd4;
            8'd154: Output=4'd4;
            8'd155: Output=4'd5;
            8'd156: Output=4'd4;
            8'd157: Output=4'd5;
            8'd158: Output=4'd5;
            8'd159: Output=4'd6;
            8'd160: Output=4'd2;
            8'd161: Output=4'd3;
            8'd162: Output=4'd3;
            8'd163: Output=4'd4;
            8'd164: Output=4'd3;
            8'd165: Output=4'd4;
            8'd166: Output=4'd4;
            8'd167: Output=4'd5;
            8'd168: Output=4'd3;
            8'd169: Output=4'd4;
            8'd170: Output=4'd4;
            8'd171: Output=4'd5;
            8'd172: Output=4'd4;
            8'd173: Output=4'd5;
            8'd174: Output=4'd5;
            8'd175: Output=4'd6;
            8'd176: Output=4'd3;
            8'd177: Output=4'd4;
            8'd178: Output=4'd4;
            8'd179: Output=4'd5;
            8'd180: Output=4'd4;
            8'd181: Output=4'd5;
            8'd182: Output=4'd5;
            8'd183: Output=4'd6;
            8'd184: Output=4'd4;
            8'd185: Output=4'd5;
            8'd186: Output=4'd5;
            8'd187: Output=4'd6;
            8'd188: Output=4'd5;
            8'd189: Output=4'd6;
            8'd190: Output=4'd6;
            8'd191: Output=4'd7;
            8'd192: Output=4'd2;
            8'd193: Output=4'd3;
            8'd194: Output=4'd3;
            8'd195: Output=4'd4;
            8'd196: Output=4'd3;
            8'd197: Output=4'd4;
            8'd198: Output=4'd4;
            8'd199: Output=4'd5;
            8'd200: Output=4'd3;
            8'd201: Output=4'd4;
            8'd202: Output=4'd4;
            8'd203: Output=4'd5;
            8'd204: Output=4'd4;
            8'd205: Output=4'd5;
            8'd206: Output=4'd5;
            8'd207: Output=4'd6;
            8'd208: Output=4'd3;
            8'd209: Output=4'd4;
            8'd210: Output=4'd4;
            8'd211: Output=4'd5;
            8'd212: Output=4'd4;
            8'd213: Output=4'd5;
            8'd214: Output=4'd5;
            8'd215: Output=4'd6;
            8'd216: Output=4'd4;
            8'd217: Output=4'd5;
            8'd218: Output=4'd5;
            8'd219: Output=4'd6;
            8'd220: Output=4'd5;
            8'd221: Output=4'd6;
            8'd222: Output=4'd6;
            8'd223: Output=4'd7;
            8'd224: Output=4'd3;
            8'd225: Output=4'd4;
            8'd226: Output=4'd4;
            8'd227: Output=4'd5;
            8'd228: Output=4'd4;
            8'd229: Output=4'd5;
            8'd230: Output=4'd5;
            8'd231: Output=4'd6;
            8'd232: Output=4'd4;
            8'd233: Output=4'd5;
            8'd234: Output=4'd5;
            8'd235: Output=4'd6;
            8'd236: Output=4'd5;
            8'd237: Output=4'd6;
            8'd238: Output=4'd6;
            8'd239: Output=4'd7;
            8'd240: Output=4'd4;
            8'd241: Output=4'd5;
            8'd242: Output=4'd5;
            8'd243: Output=4'd6;
            8'd244: Output=4'd5;
            8'd245: Output=4'd6;
            8'd246: Output=4'd6;
            8'd247: Output=4'd7;
            8'd248: Output=4'd5;
            8'd249: Output=4'd6;
            8'd250: Output=4'd6;
            8'd251: Output=4'd7;
            8'd252: Output=4'd6;
            8'd253: Output=4'd7;
            8'd254: Output=4'd7;
            8'd255: Output=4'd8;

			
		endcase

endmodule




////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

module Sumatoria(Input, Output);
    input [511:0]Input;
    output [10:0]Output;
    
    assign Output = Input[511:508] +Input[507:504] +Input[503:500] +Input[499:496] +Input[495:492] +Input[491:488] +Input[487:484] +Input[483:480] +Input[479:476] +Input[475:472] +Input[471:468] +Input[467:464] +Input[463:460] +Input[459:456] +Input[455:452] +Input[451:448] +Input[447:444] +Input[443:440] +Input[439:436] +Input[435:432] +Input[431:428] +Input[427:424] +Input[423:420] +Input[419:416] +Input[415:412] +Input[411:408] +Input[407:404] +Input[403:400] +Input[399:396] +Input[395:392] +Input[391:388] +Input[387:384] +Input[383:380] +Input[379:376] +Input[375:372] +Input[371:368] +Input[367:364] +Input[363:360] +Input[359:356] +Input[355:352] +Input[351:348] +Input[347:344] +Input[343:340] +Input[339:336] +Input[335:332] +Input[331:328] +Input[327:324] +Input[323:320] +Input[319:316] +Input[315:312] +Input[311:308] +Input[307:304] +Input[303:300] +Input[299:296] +Input[295:292] +Input[291:288] +Input[287:284] +Input[283:280] +Input[279:276] +Input[275:272] +Input[271:268] +Input[267:264] +Input[263:260] +Input[259:256] +Input[255:252] +Input[251:248] +Input[247:244] +Input[243:240] +Input[239:236] +Input[235:232] +Input[231:228] +Input[227:224] +Input[223:220] +Input[219:216] +Input[215:212] +Input[211:208] +Input[207:204] +Input[203:200] +Input[199:196] +Input[195:192] +Input[191:188] +Input[187:184] +Input[183:180] +Input[179:176] +Input[175:172] +Input[171:168] +Input[167:164] +Input[163:160] +Input[159:156] +Input[155:152] +Input[151:148] +Input[147:144] +Input[143:140] +Input[139:136] +Input[135:132] +Input[131:128] +Input[127:124] +Input[123:120] +Input[119:116] +Input[115:112] +Input[111:108] +Input[107:104] +Input[103:100] +Input[99:96] +Input[95:92] +Input[91:88] +Input[87:84] +Input[83:80] +Input[79:76] +Input[75:72] +Input[71:68] +Input[67:64] +Input[63:60] +Input[59:56] +Input[55:52] +Input[51:48] +Input[47:44] +Input[43:40] +Input[39:36] +Input[35:32] +Input[31:28] +Input[27:24] +Input[23:20] +Input[19:16] +Input[15:12]+Input[11:8]+Input[7:4]+Input[3:0];
    
endmodule


////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////


module RegistroCorrelacion(Clk, Reset, LD, Input, Output);
    input Clk, Reset;
    input LD;
    input[10:0] Input;
    output reg[10:0] Output;
    
    always @(posedge Clk)
        if(Reset)
            Output=11'd0;
        else if(LD)
            Output=Input;
        else
            Output=Output;

endmodule

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////





