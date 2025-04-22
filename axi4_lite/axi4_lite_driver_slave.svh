`ifndef AXI4_LITE_DRIVER_SLAVE_SVH
`define AXI4_LITE_DRIVER_SLAVE_SVH

/* Class: axi4_lite_driver_slave
 *
 * AXI4-Lite Slave interface driver.
 *
 * Parameters:
 *  DATA_BYTES      - Number of bytes for data signals.
 *  ADDRESS_WIDTH   - Number of bits for address signals.
 */
class axi4_lite_driver_slave #(
    int DATA_BYTES = 4,
    int ADDRESS_WIDTH = 1
);
    typedef virtual axi4_lite_if #(
        .DATA_BYTES(DATA_BYTES),
        .ADDRESS_WIDTH(ADDRESS_WIDTH)
    ) .cb_slave_modport vif_t;

    typedef axi4_lite_pkg::access_t access_t;
    typedef axi4_lite_pkg::response_t response_t;
    typedef bit [DATA_BYTES-1:0] byte_enable_t;
    typedef bit [DATA_BYTES-1:0][7:0] data_t;
    typedef bit [ADDRESS_WIDTH-1:0] address_t;

    extern function new(vif_t vif);

    extern task reset();

    extern function void set_timeout(int value);

    extern task write_request_data(data_t data,
        byte_enable_t byte_enable = '1);

    extern task write_request_address(address_t address,
        access_t access = axi4_lite_pkg::DEFAULT_DATA_ACCESS);

    extern task write_request(address_t address, data_t data,
        byte_enable_t byte_enable = '1,
        access_t access = axi4_lite_pkg::DEFAULT_DATA_ACCESS);

    extern task write_response(ref response_t response);

    extern task write_ready(bit value = 1);

    extern task read_request(address_t address,
        access_t access = axi4_lite_pkg::DEFAULT_DATA_ACCESS);

    extern task read_response(ref data_t data, ref response_t response);

    extern task read_ready(bit value = 1);

    extern task aclk_posedge(int count = 1);

    local vif_t m_vif;
    local int m_timeout;
endclass

function axi4_lite_driver_slave::new(vif_t vif);
    m_vif = vif;
    m_timeout = 0;
endfunction

function void axi4_lite_driver_slave::set_timeout(int value);
    m_timeout = value;
endfunction

task axi4_lite_driver_slave::reset();
    m_vif.cb_slave.wvalid <= 1'b0;
    m_vif.cb_slave.wdata <= 'X;
    m_vif.cb_slave.wstrb <= 'X;

    m_vif.cb_slave.awvalid <= 1'b0;
    m_vif.cb_slave.awaddr <= 'X;
    m_vif.cb_slave.awprot <= access_t'('X);

    m_vif.cb_slave.arvalid <= 1'b0;
    m_vif.cb_slave.araddr <= 'X;
    m_vif.cb_slave.arprot <= access_t'('X);

    m_vif.cb_slave.bready <= 1'b0;
    m_vif.cb_slave.rready <= 1'b0;
endtask

task axi4_lite_driver_slave::write_request_data(data_t data,
        byte_enable_t byte_enable = '1);
    bit is_running = 1;
    int timeout = (m_timeout > 0) ? m_timeout : -1;

    m_vif.cb_slave.wdata <= data;
    m_vif.cb_slave.wstrb <= byte_enable;
    m_vif.cb_slave.wvalid <= 1;

    while (is_running && (1'b1 === m_vif.areset_n)) begin
        aclk_posedge();

        if ((1'b1 === m_vif.cb_slave.wvalid) &&
                (1'b1 === m_vif.cb_slave.wready)) begin
            is_running = 0;
        end
        else if (timeout > 0) begin
            --timeout;
        end
        else if (timeout == 0) begin
            is_running = 0;
        end
    end

    m_vif.cb_slave.wvalid <= 0;
endtask

task axi4_lite_driver_slave::write_request_address(address_t address,
        access_t access = axi4_lite_pkg::DEFAULT_DATA_ACCESS);
    bit is_running = 1;
    int timeout = (m_timeout > 0) ? m_timeout : -1;

    m_vif.cb_slave.awaddr <= address;
    m_vif.cb_slave.awprot <= access;
    m_vif.cb_slave.awvalid <= 1;

    while (is_running && (1'b1 === m_vif.areset_n)) begin
        aclk_posedge();

        if ((1'b1 === m_vif.cb_slave.awvalid) &&
                (1'b1 === m_vif.cb_slave.awready)) begin
            is_running = 0;
        end
        else if (timeout > 0) begin
            --timeout;
        end
        else if (timeout == 0) begin
            is_running = 0;
        end
    end

    m_vif.cb_slave.awvalid <= 0;
endtask

task axi4_lite_driver_slave::write_request(address_t address, data_t data,
        byte_enable_t byte_enable = '1,
        access_t access = axi4_lite_pkg::DEFAULT_DATA_ACCESS);
    fork
        write_request_data(data, byte_enable);
        write_request_address(address, access);
    join
endtask

task axi4_lite_driver_slave::write_response(ref response_t response);
    bit is_running = 1;
    int timeout = (m_timeout > 0) ? m_timeout : -1;

    response = axi4_lite_pkg::RESPONSE_OKAY;

    m_vif.cb_slave.bready <= 1;

    while (is_running && (1'b1 === m_vif.areset_n)) begin
        aclk_posedge();

        if ((1'b1 === m_vif.cb_slave.bvalid) &&
                (1'b1 === m_vif.cb_slave.bready)) begin
            is_running = 0;
            response = m_vif.cb_slave.bresp;
        end
        else if (timeout > 0) begin
            --timeout;
        end
        else if (timeout == 0) begin
            is_running = 0;
        end
    end

    m_vif.cb_slave.bready <= 0;
endtask

task axi4_lite_driver_slave::write_ready(bit value = 1);
    m_vif.cb_slave.bready <= value;
endtask

task axi4_lite_driver_slave::read_request(address_t address,
        access_t access = axi4_lite_pkg::DEFAULT_DATA_ACCESS);
    bit is_running = 1;
    int timeout = (m_timeout > 0) ? m_timeout : -1;

    m_vif.cb_slave.araddr <= address;
    m_vif.cb_slave.arprot <= access;
    m_vif.cb_slave.arvalid <= 1;

    while (is_running && (1'b1 === m_vif.areset_n)) begin
        aclk_posedge();

        if ((1'b1 === m_vif.cb_slave.arvalid) &&
                (1'b1 === m_vif.cb_slave.arready)) begin
            is_running = 0;
        end
        else if (timeout > 0) begin
            --timeout;
        end
        else if (timeout == 0) begin
            is_running = 0;
        end
    end

    m_vif.cb_slave.arvalid <= 0;
endtask

task axi4_lite_driver_slave::read_response(ref data_t data,
        ref response_t response);
    bit is_running = 1;
    int timeout = (m_timeout > 0) ? m_timeout : -1;

    data = '0;
    response = axi4_lite_pkg::RESPONSE_OKAY;

    m_vif.cb_slave.rready <= 1;

    while (is_running && (1'b1 === m_vif.areset_n)) begin
        aclk_posedge();

        if ((1'b1 === m_vif.cb_slave.rvalid) &&
                (1'b1 === m_vif.cb_slave.rready)) begin
            is_running = 0;
            data = m_vif.cb_slave.rdata;
            response = m_vif.cb_slave.rresp;
        end
        else if (timeout > 0) begin
            --timeout;
        end
        else if (timeout == 0) begin
            is_running = 0;
        end
    end

    m_vif.cb_slave.rready <= 0;
endtask

task axi4_lite_driver_slave::read_ready(bit value = 1);
    m_vif.cb_slave.rready <= value;
endtask

task axi4_lite_driver_slave::aclk_posedge(int count = 1);
    while (count--) begin
        @(m_vif.cb_slave);
    end
endtask

`endif /* AXI4_LITE_DRIVER_SLAVE_SVH */
