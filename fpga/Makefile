HEADERS = $(shell find . -name '*.h')

fpga: fpga.cpp $(HEADERS)
	g++ -std=c++20 -O2 -o fpga fpga.cpp -lserial -lelf
