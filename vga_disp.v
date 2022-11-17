module vga_disp	
(
	input					clk,
	input					reset_n,

	output 				VGA_HSYNC,
	output 				VGA_VSYNC,

	output reg [11:0] VGA_D
);		

parameter H_TA = 96;
parameter H_TB = 40;
parameter H_TC = 8;
parameter H_TD = 640;
parameter H_TE=8;
parameter H_TF=8;
parameter H_BLANK=H_TA+H_TB+H_TC;
parameter H_TOTAL=H_TA+H_TB+H_TC+H_TD+H_TE+H_TF;
parameter LENGTH=100,WIDTH=90;
parameter V_TA=2;
parameter V_TB=25;
parameter V_TC=8;
parameter V_TD=480;
parameter V_TE=8;
parameter V_TF=2;
parameter V_BLANK=V_TA+V_TB+V_TC;
parameter V_TOTAL=V_TA+V_TB+V_TC+V_TD+V_TE+V_TF;

reg[1:0] ij;

reg  [9:0]		hcnt	;
reg  [9:0]		vcnt	;		
reg				hs		;	
reg   			vs		;
reg 				clk25M;

wire [2:0]  	rgb	;
reg [9:0] 		x     ;
reg [9:0] 		y     ;
wire 				dis_en;

reg[13:0] address;
wire[11:0] q;

assign VGA_VSYNC = vs;
assign VGA_HSYNC = hs;
assign dis_en = (hcnt<10'd800 && vcnt<10'd480);
assign rgb = hcnt[7:5];

wire[4:0] ired=q[11:8];
wire[4:0] igreen=q[7:4];
wire[4:0] iblue=q[3:0];

always @(posedge clk or negedge reset_n)begin
	if (!reset_n)
		clk25M <= 1'b0;
	else
		clk25M <= ~clk25M;
end
			
always @(posedge clk25M or negedge reset_n) begin			//水平扫描计数器
	if(!reset_n)
		hcnt <= 1'b0;
	else begin
		if (hcnt < 960)
			hcnt <= hcnt + 1'b1;
		else
			hcnt <= 1'b0;
	end
end
			
always @(posedge clk25M or negedge reset_n) begin			//垂直扫描计数器
	if(!reset_n)
		vcnt <= 1'b0;
	else begin
		if (hcnt == 10'd800 + 10'd8) begin
			if (vcnt < 10'd525)
				vcnt <= vcnt +1'b1;
			else
				vcnt <= 1'b0;
		end
	end
end
			
always @(posedge clk25M or negedge reset_n) begin			//场同步信号发生
	if(!reset_n)
		hs	<=	1'b1;
	else begin
		if((hcnt >= 800+8+8) & (hcnt < 800+8+8+96))
			hs <= 1'b0;
		else
			hs <= 1'b1;
	end
end
			
always @(vcnt or reset_n) begin							//行同步信号发生
	if(!reset_n)
		vs	<=	1'b1;
	else begin
		if((vcnt >= 480+8+2) && (vcnt < 480+8+2+2))
			vs	<=	1'b0;
		else
			vs	<=	1'b1;
	end
end
			
/* always @(posedge clk25M or negedge reset_n) begin
	if(!reset_n)
		VGA_D <= 1'b0;
	else begin
		if (hcnt < 10'd800 & vcnt < 10'd480 && dis_en)	begin	
			VGA_D[11:8] <= rgb[0]?4'hf:0;
			VGA_D[ 7:4] <= rgb[1]?4'hf:0;
			VGA_D[ 3:0] <= rgb[2]?4'hf:0;
		end
		else begin
			VGA_D <= 1'b0;
		end
	end
end */

always @(posedge clk25M or negedge reset_n) begin
	if(!reset_n)
		VGA_D <= 1'b0;
	else begin
		if (hcnt<(x+H_TA+LENGTH)&&(hcnt>=x+H_TA)&&vcnt<(y+V_TA+
        V_TB+V_TC+WIDTH)&&(vcnt>=y+V_TA+V_TB+V_TC))	begin	
			address<=address+1;
			VGA_D[11:8] <= ired;
			VGA_D[ 7:4] <= igreen;
			VGA_D[ 3:0] <= iblue;
		end
		else begin
			VGA_D <= 1'b0;
		end
	end
end

always@(negedge vs)
begin     if(ij==2'b00)  begin
        x<=x+1;   y<=y+1;
        if(y+WIDTH==480)          ij<=2'b01;
        else if(x+LENGTH==640)    ij<=2'b10;
        end
        else if(ij==2'b01)  begin
        x<=x+1;   y<=y-1;
        if(x+LENGTH==640)    ij<=2'b11;
        else if(y==0)        ij<=2'b00;
        end
     else if(ij==2'b10)
     begin
        x<=x-1;   y<=y+1;
        if(x==0)     ij<=2'b00;
        else if(y+WIDTH==480)  ij<=2'b11;
     end
     else if(ij==2'b11)
     begin  x<=x-1;     y<=y-1;
        if(x==0)     ij<=2'b01;
        else if(y==0)ij<=2'b10;
     end
end

aimi u_aimi(
	.address (address ),
	.clock   (clk25M   ),
	.q       (q       )
);

endmodule 
