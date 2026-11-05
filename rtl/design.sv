`timescale 1ns/1ps

interface apb_if(
    input logic PCLK,
    input logic PRESETn
);

    logic [7:0]  PADDR;
    logic        PSEL;
    logic        PENABLE;
    logic        PWRITE;
    logic [31:0] PWDATA;

    logic [31:0] PRDATA;
    logic        PREADY;
    logic        PSLVERR;


    modport master(

        input  PCLK,
        input  PRESETn,

        output PADDR,
        output PSEL,
        output PENABLE,
        output PWRITE,
        output PWDATA,

        input  PRDATA,
        input  PREADY,
        input  PSLVERR

    );


    modport slave(

        input  PCLK,
        input  PRESETn,

        input  PADDR,
        input  PSEL,
        input  PENABLE,
        input  PWRITE,
        input  PWDATA,

        output PRDATA,
        output PREADY,
        output PSLVERR

    );

endinterface



module apb_slave_ram(

    apb_if.slave apb

);

    logic [31:0] memory [0:3];
    logic valid_address;

    integer i;


    assign valid_address =
        (apb.PADDR[1:0] == 2'b00) &&
        (apb.PADDR <= 8'h0C);


    always_comb
    begin

        apb.PRDATA  = 32'h0000_0000;
        apb.PREADY  = 1'b0;
        apb.PSLVERR = 1'b0;

        if(apb.PSEL && apb.PENABLE)
        begin

            apb.PREADY = 1'b1;

            if(!valid_address)
            begin

                apb.PSLVERR = 1'b1;

            end
            else if(!apb.PWRITE)
            begin

                apb.PRDATA =
                    memory[apb.PADDR[3:2]];

            end

        end

    end


    always_ff @(posedge apb.PCLK or negedge apb.PRESETn)
    begin

        if(!apb.PRESETn)
        begin

            for(i = 0; i < 4; i = i + 1)
            begin

                memory[i] <= 32'h0000_0000;

            end

        end
        else
        begin

            if(
                apb.PSEL &&
                apb.PENABLE &&
                apb.PREADY &&
                apb.PWRITE &&
                !apb.PSLVERR
            )
            begin

                memory[apb.PADDR[3:2]]
                    <= apb.PWDATA;

            end

        end

    end

endmodule