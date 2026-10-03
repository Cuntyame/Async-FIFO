`include "uvm_macros.svh"
import uvm_pkg::*;

class fifo_seq_item extends uvm_sequence_item;
    
    // 1. Declare your randomized inputs here (use the 'rand' keyword)
    // Hint: What signals does the testbench actively drive to make a transfer happen?
    rand bit w_en;
    rand bit r_en;
    rand bit [15:0] data_in;
    bit empty;
    bit [15:0] data_out;
    bit full;
   // 2. Declare your output signals here (DO NOT use 'rand')
   // Hint: What signals do we need to capture from the DUT to check if it worked?

    // UVM Factory Registration (Leave this as-is)
    `uvm_object_utils(fifo_seq_item)

    // Constructor
    function new(string name = "fifo_seq_item");
        super.new(name);
    endfunction

    // 3. Write a constraint here
    // Hint: If UVM purely randomizes the inputs, it will sometimes generate 
    // a packet where BOTH write_enable and read_enable are 0. That's a useless 
    // blank cycle. Write a constraint to prevent that specific scenario.
    constraint c_useful_stimulus {
        !(w_en==0 && r_en==0);
    }

endclass

class fifo_sequence extends uvm_sequence #(fifo_seq_item);
    `uvm_object_utils(fifo_sequence)

    function new(string name = "fifo_sequence");
        super.new(name);
    endfunction

    // The body() task is the main execution block of the sequence
    task body();
        fifo_seq_item req; // Declare a handle for your packet
        for(int i=0;i<50;i++)
        begin
            req = fifo_seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize()) `uvm_error("SEQ", "Randomize failed");
            finish_item(req);
        end
        // Your Job: Write a loop that runs 50 times.
        // Inside the loop, you must do 4 specific UVM steps to create and send a packet:
        // 1. Create it:       req = fifo_seq_item::type_id::create("req");
        // 2. Start it:        start_item(req);
        // 3. Randomize it:    if (!req.randomize()) `uvm_error("SEQ", "Randomize failed")
        // 4. Send it:         finish_item(req);
    endtask
endclass

interface fifo_if (input logic wclk, input logic rclk);
    
    // Declare your resets (wrst_n, rrst_n)
    logic rrst_n;
    logic wrst_n;

    // Declare your write domain signals (w_en, data_in, full)
    logic w_en;
    logic full;
    logic r_en;
    logic empty;
    logic [15:0] data_in;
    logic [15:0] data_out;
    // Declare your read domain signals (r_en, data_out, empty)
endinterface

class fifo_driver extends uvm_driver #(fifo_seq_item);
    `uvm_component_utils(fifo_driver)

    // This is the virtual handle to the physical interface bridge
    virtual fifo_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // UVM grabs the interface from the testbench config database
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "Could not get virtual interface")
    endfunction

    // The actual driving logic
    task run_phase(uvm_phase phase);
        // 1. Initialize your driving signals safely to 0
        vif.w_en <= 0;
        vif.r_en <= 0;
        vif.data_in <= 0;

        // Wait for both resets to go high before we start asking for packets
        wait(vif.wrst_n == 1 && vif.rrst_n == 1);

        forever begin
            seq_item_port.get_next_item(req); // Ask sequence for a packet

            // YOUR JOB: Drive the pins based on the 'req' packet
            fork
                // Thread 1: The Write Domain
                begin
                    if (req.w_en==1 && vif.full==0)begin
                      @(posedge vif.wclk );
                        vif.data_in=req.data_in;
                        vif.w_en=req.w_en;
                    //   end
                        @(posedge vif.wclk);
                      vif.w_en=0;
                    end
                    // If req.w_en is 1 AND the FIFO is not full (vif.full)
                    // Wait for posedge of vif.wclk
                    // Drive vif.w_en and vif.data_in using the values from 'req'
                    // Wait for the next posedge of vif.wclk
                    // Set vif.w_en back to 0
                end
                
                // Thread 2: The Read Domain
                begin
                    if(req.r_en==1 && vif.empty==0) begin
                        @(posedge vif.rclk ); 
                            // vif.data_out=req.data_out;
                            vif.r_en=req.r_en;
                            @(posedge vif.rclk);
                        vif.r_en=0;
                    end
                    // If req.r_en is 1 AND the FIFO is not empty (vif.empty)
                    // Wait for posedge of vif.rclk
                    // Drive vif.r_en using the value from 'req'
                    // Wait for the next posedge of vif.rclk
                    // Set vif.r_en back to 0
                end
            join

            seq_item_port.item_done(); // Tell sequence we finished the packet
        end
    endtask
endclass

class fifo_sequencer extends uvm_sequencer #(fifo_seq_item);
    `uvm_component_utils(fifo_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

class fifo_agent extends uvm_agent;
    `uvm_component_utils(fifo_agent)

    // Declare handles to our components
    fifo_driver    drv;
    fifo_sequencer sqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // Build Phase: Create the components
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = fifo_driver::type_id::create("drv", this);
        sqr = fifo_sequencer::type_id::create("sqr", this);
    endfunction

    // Connect Phase: Wire them together
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
        // YOUR JOB: Connect the driver's port to the sequencer's export.
        // Hint: [driver_handle].[port_name].connect([sequencer_handle].[export_name]);
        
    endfunction
endclass
class fifo_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_monitor)

    virtual fifo_if vif;
    
    // The megaphone port to broadcast captured packets
    uvm_analysis_port #(fifo_seq_item) ap; 

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this); // Initialize the port
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "Could not get virtual interface")
    endfunction

    task run_phase(uvm_phase phase);
        fifo_seq_item captured_item;

        // Wait for resets to clear
        wait(vif.wrst_n == 1 && vif.rrst_n == 1);

        fork
            // Thread 1: Watch the Write Domain
            forever begin
                @(posedge vif.wclk);
                if (vif.w_en == 1 && vif.full == 0) begin
                    // YOUR JOB:
                    captured_item=fifo_seq_item::type_id::create("captured_item");
                    // captured_item=fifo_driver::type_id::create('captured_item',this);
                    // 1. Create 'captured_item' using the factory (type_id::create)
                    captured_item.data_in=vif.data_in;
                    captured_item.w_en=1;
                    ap.write(captured_item);
                    // 2. Copy vif.data_in into captured_item.data_in
                    // 3. Set captured_item.w_en = 1
                    // 4. Broadcast it: ap.write(captured_item);
                end
            end

            // Thread 2: Watch the Read Domain
            forever begin
                @(posedge vif.rclk);
                if (vif.r_en == 1 && vif.empty == 0) begin
                    // YOUR JOB:
                    @(posedge vif.rclk);
                    captured_item=fifo_seq_item::type_id::create("captured_item");
                    captured_item.data_out=vif.data_out;
                    captured_item.r_en=1;
                    ap.write(captured_item);
                    
                    // 1. Wait for ONE MORE posedge of rclk (because of RAM read latency!)
                    // 2. Create 'captured_item' using the factory (type_id::create)
                    // 3. Copy vif.data_out into captured_item.data_out
                    // 4. Set captured_item.r_en = 1
                    // 5. Broadcast it: ap.write(captured_item);
                end
            end
        join
    endtask
endclass

class fifo_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fifo_scoreboard)

    // The receiving end of the pneumatic tube from the Monitor
    uvm_analysis_imp #(fifo_seq_item, fifo_scoreboard) item_collected_export;

    // A golden software queue to act as our perfect, ideal FIFO
    bit [15:0] expected_queue[$];

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_export = new("item_collected_export", this);
    endfunction

    // This function automatically executes EVERY TIME the monitor broadcasts a packet
    virtual function void write(fifo_seq_item pkt);
        bit [15:0]  temp;   
        // YOUR JOB:
        // 1. If this packet was a write operation (pkt.w_en == 1):
        //    Push pkt.data_in into the expected_queue.
        //    Print an info message: `uvm_info("SCB", $sformatf("Stored Data: %0h", pkt.data_in), UVM_LOW)
        if(pkt.w_en==1)begin
            expected_queue.push_back(pkt.data_in);
            `uvm_info("SCB", $sformatf("Stored Data: %0h", pkt.data_in), UVM_LOW);
        end
        // 2. If this packet was a read operation (pkt.r_en == 1):
        if(pkt.r_en==1)begin
            temp=expected_queue.pop_front();
            if(pkt.data_out==temp)
                `uvm_info("SCB","PASS:data matched!",UVM_LOW);
            else
                // print('uvm_error("SCB", ...));
                `uvm_error("SCB",$sformatf("FAILED:expected %0h ,got %0h", temp ,pkt_data_out));
        //    Pop expected data from the queue into a temporary variable (e.g., bit [15:0] exp_data)
        end
        //    Compare exp_data against pkt.data_out.
        //    If they match, print a PASS message.
        //    If they mismatch, print a FAIL message (`uvm_error("SCB", ...))
        
    endfunction
endclass

class fifo_env extends uvm_env;
    `uvm_component_utils(fifo_env)

    // Declare the handles
    fifo_agent      agt;
    fifo_scoreboard scb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = fifo_agent::type_id::create("agt", this);
        scb = fifo_scoreboard::type_id::create("scb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // This is the line that connects the Monitor to the Scoreboard!
        agt.mon.ap.connect(scb.item_collected_export);
        
    endfunction
endclass