`timescale 1ns/1ps

module tb_apb_modport;

    logic PCLK;
    logic PRESETn;

    logic [31:0] read_data0;
    logic [31:0] read_data1;

    integer pass_count;
    integer fail_count;


    apb_if apb_bus(

        .PCLK    (PCLK),
        .PRESETn (PRESETn)

    );


    apb_slave_ram dut(

        .apb(apb_bus)

    );


    class apb_master_test;

        virtual apb_if.master vif;


        function new(

            virtual apb_if.master vif

        );

            this.vif = vif;

        endfunction


        task initialize();

            vif.PADDR   = 8'h00;
            vif.PSEL    = 1'b0;
            vif.PENABLE = 1'b0;
            vif.PWRITE  = 1'b0;
            vif.PWDATA  = 32'h0000_0000;

        endtask


        task write(

            input logic [7:0]  address,
            input logic [31:0] data

        );

        begin

            @(negedge vif.PCLK);

            vif.PADDR   = address;
            vif.PWDATA  = data;
            vif.PWRITE  = 1'b1;

            vif.PSEL    = 1'b1;
            vif.PENABLE = 1'b0;


            @(negedge vif.PCLK);

            vif.PENABLE = 1'b1;


            @(posedge vif.PCLK);

            while(vif.PREADY != 1'b1)
            begin

                @(posedge vif.PCLK);

            end


            #1;

            if(vif.PSLVERR == 1'b0)
            begin

                $display(
                    "WRITE PASS : ADDR=%h DATA=%h",
                    address,
                    data
                );

            end
            else
            begin

                $display(
                    "WRITE ERROR : ADDR=%h",
                    address
                );

            end


            @(negedge vif.PCLK);

            vif.PSEL    = 1'b0;
            vif.PENABLE = 1'b0;
            vif.PWRITE  = 1'b0;

        end

        endtask


        task read(

            input  logic [7:0]  address,
            output logic [31:0] data

        );

        begin

            @(negedge vif.PCLK);

            vif.PADDR   = address;
            vif.PWRITE  = 1'b0;

            vif.PSEL    = 1'b1;
            vif.PENABLE = 1'b0;


            @(negedge vif.PCLK);

            vif.PENABLE = 1'b1;


            @(posedge vif.PCLK);

            while(vif.PREADY != 1'b1)
            begin

                @(posedge vif.PCLK);

            end


            #1;

            data = vif.PRDATA;


            $display(
                "READ : ADDR=%h DATA=%h ERROR=%b",
                address,
                data,
                vif.PSLVERR
            );


            @(negedge vif.PCLK);

            vif.PSEL    = 1'b0;
            vif.PENABLE = 1'b0;

        end

        endtask

    endclass



    apb_master_test master;


    always #5 PCLK = ~PCLK;



    initial
    begin

        $dumpfile("apb_modport.vcd");
        $dumpvars(0, tb_apb_modport);


        PCLK       = 1'b0;
        PRESETn    = 1'b0;

        read_data0 = 32'h0000_0000;
        read_data1 = 32'h0000_0000;

        pass_count = 0;
        fail_count = 0;


        master = new(apb_bus);

        master.initialize();


        repeat(3)
            @(posedge PCLK);


        @(negedge PCLK);

        PRESETn = 1'b1;


        // ROOHAN TEST DATA
        // 72 6F 6F 68 = rooh
        // 61 6E 20 20 = an


        master.write(

            8'h00,
            32'h726F6F68

        );


        master.write(

            8'h04,
            32'h616E2020

        );


        master.read(

            8'h00,
            read_data0

        );


        master.read(

            8'h04,
            read_data1

        );


        if(read_data0 == 32'h726F6F68)
        begin

            $display(
                "PASS : FIRST ROOHAN DATA CORRECT"
            );

            pass_count = pass_count + 1;

        end
        else
        begin

            $display(
                "FAIL : FIRST DATA INCORRECT"
            );

            fail_count = fail_count + 1;

        end


        if(read_data1 == 32'h616E2020)
        begin

            $display(
                "PASS : SECOND ROOHAN DATA CORRECT"
            );

            pass_count = pass_count + 1;

        end
        else
        begin

            $display(
                "FAIL : SECOND DATA INCORRECT"
            );

            fail_count = fail_count + 1;

        end


        $display("");
        $display("-----------------------------------");
        $display("ROOHAN PART 1 = %h", read_data0);
        $display("ROOHAN PART 2 = %h", read_data1);
        $display("-----------------------------------");


        $display(
            "TOTAL PASSED = %0d",
            pass_count
        );

        $display(
            "TOTAL FAILED = %0d",
            fail_count
        );


        if(fail_count == 0)
        begin

            $display(
                "ALL APB TESTS PASSED"
            );

        end
        else
        begin

            $display(
                "APB TEST FAILED"
            );

        end


        #20;

        $finish;

    end

endmodule